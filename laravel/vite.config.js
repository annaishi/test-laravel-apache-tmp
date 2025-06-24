import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';
import tailwindcss from '@tailwindcss/vite';
import vue from '@vitejs/plugin-vue';
import { fileURLToPath, URL } from "node:url";

export default defineConfig({
    plugins: [
        laravel({
            input: [
                'resources/css/app.css', 
                'resources/js/app.js',
                'resources/css/reset.css',
            ],
            refresh: true,
        }),
        tailwindcss(),
        vue({
        template: {
            transformAssetUrls: {
                base: null,
                includeAbsolute: false,
                },
            },
        }),
    ],
    server: {
        host: true,
        port: '55173',
        hmr: { host: 'localhost' },
    },
    resolve: {
        alias: {
          // DOM内テンプレートを使用する場合この指定が必要
          vue: "vue/dist/vue.esm-bundler.js",
          "@pages": fileURLToPath(new URL("./resources/js/pages", import.meta.url)),
        },
      },
});
