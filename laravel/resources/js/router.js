import { createWebHistory, createRouter } from "vue-router";

import Example from "@pages/Example.vue";

const routes = [{ path: "/example", name: "example", component: Example }];

export const router = createRouter({
  history: createWebHistory(),
  routes,
});