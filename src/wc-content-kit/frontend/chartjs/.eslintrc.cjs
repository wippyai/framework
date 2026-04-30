/** @type {import('eslint').Linter.Config} */
module.exports = {
  root: true,
  parser: 'vue-eslint-parser',
  parserOptions: {
    parser: '@typescript-eslint/parser',
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
  plugins: ['@typescript-eslint'],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/strict',
    'plugin:vue/vue3-recommended',
  ],
  rules: {
    '@typescript-eslint/no-explicit-any': 'warn',
    '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_', varsIgnorePattern: '^_' }],
    '@typescript-eslint/no-non-null-assertion': 'warn',
    '@typescript-eslint/consistent-type-imports': ['error', { prefer: 'type-imports' }],
    '@typescript-eslint/no-empty-function': 'off',
    '@typescript-eslint/no-extraneous-class': 'off',
    '@typescript-eslint/no-invalid-void-type': 'off',
    'vue/multi-word-component-names': 'off',
    'vue/no-v-html': 'off',
    'no-console': ['warn', { allow: ['warn', 'error'] }],
    'eqeqeq': 'error',
    'no-var': 'error',
    'prefer-const': 'error',
  },
  env: {
    browser: true,
    es2020: true,
  },
}
