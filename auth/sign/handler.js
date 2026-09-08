const http = require('http');
const https = require('https');
const { URL } = require('url');
const { cpf } = require('cpf-cnpj-validator');
const { getConfig } = require('../shared/config');
const { sign } = require('../shared/jwt');

function json(statusCode, body) {
    return {
        statusCode,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
    };
}

function parseBody(event) {
    try {
        return JSON.parse(event.body || '{}');
    } catch {
        return null;
    }
}

function lookupCliente(cpfValue, backendUrl, trustSecret) {
    const target = new URL(`/api/internal/auth/clientes/${encodeURIComponent(cpfValue)}`, backendUrl);
    const client = target.protocol === 'https:' ? https : http;

    return new Promise((resolve, reject) => {
        const request = client.request(
            target,
            {
                method: 'GET',
                headers: {
                    'x-gateway-trust': trustSecret,
                    accept: 'application/json',
                },
            },
            (response) => {
                const chunks = [];
                response.on('data', (chunk) => chunks.push(chunk));
                response.on('end', () => {
                    const raw = Buffer.concat(chunks).toString('utf8');
                    let parsed = null;
                    try {
                        parsed = raw ? JSON.parse(raw) : null;
                    } catch {
                        parsed = null;
                    }
                    resolve({ statusCode: response.statusCode || 502, body: parsed });
                });
            }
        );

        request.setTimeout(8000, () => request.destroy(new Error('Timeout ao consultar cliente')));
        request.on('error', reject);
        request.end();
    });
}

exports.handler = async (event) => {
    const body = parseBody(event);
    if (!body) {
        return json(400, { error: 'Invalid JSON body' });
    }

    const rawCpf = body.cpf;
    if (!rawCpf) {
        return json(400, { error: 'CPF é obrigatório' });
    }

    const stripped = cpf.strip(String(rawCpf));
    if (!cpf.isValid(stripped)) {
        return json(400, { error: 'CPF inválido' });
    }

    const { backendUrl, gatewayTrustSecret } = getConfig();

    let lookup;
    try {
        lookup = await lookupCliente(stripped, backendUrl, gatewayTrustSecret);
    } catch (error) {
        return json(502, {
            error: 'Falha ao consultar o cliente na base',
            detail: error.message,
        });
    }

    if (lookup.statusCode === 404) {
        return json(401, { error: 'Cliente não encontrado' });
    }

    if (lookup.statusCode !== 200 || !lookup.body) {
        return json(lookup.statusCode >= 400 ? lookup.statusCode : 502, {
            error: lookup.body?.error || 'Falha ao consultar o cliente na base',
        });
    }

    if (lookup.body.status !== 'ATIVO') {
        return json(403, { error: 'Cliente inativo' });
    }

    const token = sign({
        userId: String(lookup.body.id),
        cpf: String(lookup.body.cpf),
        email: String(lookup.body.email),
    });

    return json(200, { token });
};
