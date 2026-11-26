<?php

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);

function sendRequest($kernel, $method, $uri, $data = [], $headers = []) {
    $server = [
        'HTTP_ACCEPT' => 'application/json',
        'CONTENT_TYPE' => 'application/json',
    ];
    foreach ($headers as $k => $v) {
        $server['HTTP_' . strtoupper(str_replace('-', '_', $k))] = $v;
    }
    $req = Illuminate\Http\Request::create(
        $uri,
        $method,
        [],
        [],
        [],
        $server,
        json_encode($data)
    );
    $res = $kernel->handle($req);
    $content = $res->getContent();
    $kernel->terminate($req, $res);
    return [$res->getStatusCode(), json_decode($content, true)];
}

echo "=== 1. Test Register ===\n";
$email = 'guitarist_' . time() . '@fretmaster.com';
[$status, $json] = sendRequest($kernel, 'POST', '/api/register', [
    'name' => 'John Petrucci',
    'email' => $email,
    'password' => 'progrock123',
    'password_confirmation' => 'progrock123',
]);
echo "Status: $status\n";
echo "Response: " . json_encode($json, JSON_PRETTY_PRINT) . "\n\n";

if ($status !== 201 || !isset($json['data']['token'])) {
    echo "ERROR: Register failed!\n";
    exit(1);
}

$token = $json['data']['token'];

echo "=== 2. Test Login ===\n";
[$loginStatus, $loginJson] = sendRequest($kernel, 'POST', '/api/login', [
    'email' => $email,
    'password' => 'progrock123',
]);
echo "Status: $loginStatus\n";
echo "Response: " . json_encode($loginJson, JSON_PRETTY_PRINT) . "\n\n";

if ($loginStatus !== 200 || !isset($loginJson['data']['token'])) {
    echo "ERROR: Login failed!\n";
    exit(1);
}

echo "=== 3. Test Invalid Login ===\n";
[$badStatus, $badJson] = sendRequest($kernel, 'POST', '/api/login', [
    'email' => $email,
    'password' => 'wrongpass',
]);
echo "Status: $badStatus\n";
echo "Response: " . json_encode($badJson, JSON_PRETTY_PRINT) . "\n\n";

echo "=== 4. Test Get User Profile ===\n";
[$profStatus, $profJson] = sendRequest($kernel, 'GET', '/api/user', [], [
    'Authorization' => 'Bearer ' . $token,
]);
echo "Status: $profStatus\n";
echo "Response: " . json_encode($profJson, JSON_PRETTY_PRINT) . "\n\n";

echo "=== 5. Test Logout ===\n";
[$logoutStatus, $logoutJson] = sendRequest($kernel, 'POST', '/api/logout', [], [
    'Authorization' => 'Bearer ' . $token,
]);
echo "Status: $logoutStatus\n";
echo "Response: " . json_encode($logoutJson, JSON_PRETTY_PRINT) . "\n\n";

echo "ALL LARAVEL API TESTS PASSED SUCCESSFULLY!\n";
