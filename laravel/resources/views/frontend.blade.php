<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <!-- タイトルはJS側で変更する -->
    <title>Laravel</title>

    <!-- Fonts -->
    <!-- 外部リソースの読み込みはせず、将来的にカスタムフォントを使うならローカルのアセットを使用する -->
    {{-- <link rel="preconnect" href="https://fonts.bunny.net">
    <link href="https://fonts.bunny.net/css?family=instrument-sans:400,500,600" rel="stylesheet" /> --}}

    <!-- csrf-token(axios以外のajax通信用にcsrfトークンを保持) -->
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <!-- Styles / Scripts -->
    @if (file_exists(public_path('build/manifest.json')) || file_exists(public_path('hot')))
        <!-- Vueのエントリーポイント、tailwindは使用せず削除し、リセットcssを追加 -->
        @vite(['resources/js/app.js', 'resources/css/reset.css'])
    @endif
</head>

<body>
    <div id="app"></div>
</body>

</html>