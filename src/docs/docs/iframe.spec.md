# Wippy Iframe Protocol

This document describes the protocol that dynamic pages must follow to be embeddable within the Wippy application. By implementing this protocol, your page can be loaded as an iframe and will have access to Wippy's configuration, parent window communication, and authenticated API requests.

## Initialization

To integrate with Wippy, use getWippyAPI promise or global $W variable

Access methods from getWippyAPI():

```typescript
// Access config directly
const config = await getWippyApi().then(api => api.config)
```

Or with $W global variable

```typescript
// Or use the $W global object for convenience
const config = await $W.config()
const api = await $W.api()
const form = await $W.form()
const iframe = await $W.iframe()
const on = await $W.on()
```

The initialization returns four main components:

1. `config`: Application configuration
2. `iframe`: Parent window communication methods
3. `api`: Authenticated axios instance for API requests with automatic auth token injection
4. `form`: Form state management helpers
5. `on`: Subscription to real time events from WebSocket layer

## Parent Window Communication

The `iframe` object provides methods to communicate with the parent window:

### Start a New Chat
```typescript
/**
 * Start a new chat session
 * @param start_token Token to start the chat session
 * @param sidebar Whether to open the chat in the sidebar (true) or main area (false)
 */
iframe.startChat(start_token, sidebar = false)
```
Initiates a new chat session using the provided token. Use the `sidebar` parameter to determine whether the chat should open in the right sidebar panel (when `true`) or in the main content area (when `false`).

### Set Chat Context
```typescript
/**
 * Set the context for a chat session
 * Chat session is identified by last call of startChat or openSession
 * If no chat session was started, this will apply to the next chat session started or opened
 * @param context Context object containing arbitrary data
 */
iframe.sendContext(context: Record<string, unknown>)
```
Sets the context for the current chat session. This context can include any arbitrary data that you want to pass along with the chat session. If no chat session has been started yet, this context will be applied to the next chat session that is initiated.

### Open Existing Session
```typescript
/**
 * Open an existing chat session
 * @param sessionUUID UUID of the chat session
 * @param sidebar Whether to open the session in the sidebar (true) or main area (false)
 */
iframe.openSession(sessionUUID, sidebar = false)
```
Navigates to an existing chat session. Set `sidebar` to `true` to open the session in the right sidebar panel instead of the main content area.

### Confirmation Dialog
```typescript
/**
 * Show a confirmation dialog
 * @param options ConfirmationOptions from 'primevue/confirmationoptions'
 * @returns Promise<boolean> Resolves to true if accepted, false if rejected
 */
iframe.confirm(options)
```
Shows a PrimeVue confirmation dialog with customizable options. The options follow the PrimeVue ConfirmationOptions interface.

Example:
```typescript
iframe.confirm({
    message: 'Welcome to Wippy! This is your first time here. Would you like to see a tutorial?',
    header: 'Welcome',
    icon: 'tabler:robot',
    acceptLabel: 'Yes, Please',
    rejectLabel: 'Cancel',
    acceptClass: 'p-button-primary',
    rejectClass: 'p-button-secondary',
}).then((result) => {
    if(result) {
        // User accepted
    } else {
        // User rejected
    }
}).catch((err) => {
    console.error('Confirmation failed:', err);
});
```

### Toast Messages
```typescript
/**
 * Show a toast message
 * @param options ToastMessageOptions from 'primevue/toast'
 */
iframe.toast(options)
```
Shows a PrimeVue toast message with customizable options. The options follow the PrimeVue ToastMessageOptions interface.

Example:
```typescript
iframe.toast({
    severity: 'info',
    summary: 'Tutorial',
    detail: 'Starting tutorial...'
});
```

Common toast severities:
- `success`: Green success message
- `info`: Blue information message
- `warn`: Yellow warning message
- `error`: Red error message

### Navigation
```typescript
/**
 * Navigate to a specific URL
 * @param url URL to navigate to
 */
iframe.navigate(url)
```
Requests navigation to a specific URL. The following URL patterns are supported:

- `/c/<dynamic-page-id>` - Navigates to a dynamic page with `<id>` as the dynamic page ID
- `/chat/<session-id>` - Navigates to a chat session with `<id>` as the session ID

For dynamic pages with additional path segments and query parameters, the full path after the page ID is available in the `config.path` variable. For example:

- URL: `/c/123/something/else?foo=1&bar=2`
  - Page ID: `123`
  - `config.path`: `/something/else?foo=1&bar=2`

Example:
```typescript
// Navigate to a dynamic page
iframe.navigate('/c/123')

// Navigate to a chat session
iframe.navigate('/chat/abc-xyz')

// Access the current path in your dynamic page
const { config } = await getWippyApi()
console.log(config.path) // e.g., '/something/else?foo=1&bar=2'
```

### Error Handling
```typescript
/**
 * Report an error to the parent window
 * @param type Type of error: 'auth-expired' or 'other'
 * @param error Error object Record<string, unknown>
 */
iframe.handleError(type, error)
```
Reports errors to the parent window for handling.

## Form Handling

The `form` object provides methods to work with forms and manage form state:

### Get Form State
```typescript
/**
 * Get the current state of a form
 * @returns Promise<FormState> Current form state
 */
form.get()
```
Retrieves the current state of the form, including any saved data and status information.

### Submit Form
```typescript
/**
 * Submit form data
 * @param data Form data to submit, either FormData or Record<string, unknown>
 * @returns Promise<FormResult> Result of form submission
 */
form.submit(data)
```
Submits form data and returns the result of the submission.

The form API uses the following interfaces:

```typescript
interface FormState {
  data?: Record<string, unknown> // Form field values
  status: 'active' | 'inactive' // Form status
}

interface FormResult {
  success: boolean // Whether the submission was successful
  message?: string // Optional message to display to the user
  errors?: Record<string, string> // Field-specific error messages
}
```

Example usage:
```typescript
// Initialize the API
const { form } = await getWippyApi()

// Load the current form state
try {
  const formState = await form.get()

  // Populate form with existing data
  if (formState.data) {
    populateFormFields(formState.data)
  }

  // Check form status
  if (formState.status === 'inactive') {
    disableForm()
  }
}
catch (error) {
  console.error('Failed to load form state:', error)
}

// Submit form data
async function submitForm(formData) {
  try {
    const result = await form.submit(formData)

    if (result.success) {
      showSuccessMessage(result.message)
    }
    else {
      showErrorMessage(result.message)
      displayFieldErrors(result.errors)
    }
  }
  catch (error) {
    console.error('Form submission failed:', error)
  }
}
```

## Icon Guidelines

Use the Iconify web component for all icons:

```html
<!-- Include the script -->
<script src="https://code.iconify.design/iconify-icon/2.3.0/iconify-icon.min.js"></script>

<!-- Use icons with the tabler: prefix -->
<iconify-icon icon="tabler:user" width="24" height="24"></iconify-icon>
```

Common icons:
- User: `tabler:user`
- Alert: `tabler:alert-circle`
- Success: `tabler:circle-check`
- Loading: `tabler:loader` (add `rotate="rotate"` for spinner)
- Calendar: `tabler:calendar`
- Settings: `tabler:settings`
- Add: `tabler:plus`

Style with Tailwind: `<iconify-icon icon="tabler:alert-circle" class="text-red-500"></iconify-icon>`

Browse all icons at [tabler-icons.io](https://tabler-icons.io/)

## API Requests

The `api` object is an axios instance pre-configured with:
- Base URL from environment
- Content-Type header
- Automatic token injection for authenticated requests

Example usage:
```typescript
// Make an authenticated API request
const response = await api.get('/some-endpoint')

// Post data with authentication
const result = await api.post('/another-endpoint', {
  data: 'value'
})
```

## Configuration

The `config` object contains application configuration including:
- Current widget sub-path, i.e. if App url is `/c/<dynamic-page-id>/<subpath>` config.path would contain `/<subpath>`
- Other application settings

Example:
```typescript
// Current subpath for a page
console.log(config.path)
```

## Event Subscription

The `on` property provides methods to subscribe to events from the parent window:

### History Tracking
```typescript
// Subscribe to parent window URL changes
on('@history', ({ path }) => {
  console.log('Parent URL changed:', path)
})
```

### Message Subscription
```typescript
// Subscribe to all messages
on('@message', ({ message }) => {
  console.log('Received message:', message)
})

// Subscribe to specific topic patterns
on('session:*:message:*', ({ message }) => {
  console.log('Received session message:', message)
})
```

The message subscription supports wildcard patterns:
- `*` matches any single segment
- `*:*` matches any two segments
- `*:*:*:*` matches any four segments
- Specific patterns like `session:123:message:456` match exact values
- Note if parts have ":" separator in themselves it has to be encoded (via encodeURIComponent)

Example usage:
```typescript
// Initialize the API
const { on } = await getWippyApi()

// Track parent window navigation
on('@history', ({ path }) => {
  // Update your UI based on parent URL changes
  updateNavigationState(path)
})

// Listen for specific message patterns
on('session:' + encodeURIComponent('session:id:that:has:semicolons') + ':message:*', ({ message }) => {
  // Handle session messages
  handleSessionMessage(message)
})

// Listen for all Websocket topics (specifically *, *:* and *:*:*:*)
on('@message', ({ message }) => {
  // Handle any message
  handleMessage(message)
})
```

## TypeScript Support

For TypeScript users, you can define types for the API:

```typescript
interface FormState {
  data?: Record<string, unknown>
  status: 'active' | 'inactive'
}

interface FormResult {
  success: boolean
  message?: string
  errors?: Record<string, string>
}

interface WippyApi {
  config: {
    path?: string
    artifactId?: string
  }
  iframe: {
    startChat: (start_token: string, sidebar?: boolean) => void
    openSession: (sessionUUID: string, sidebar?: boolean) => void
    navigate: (url: string) => void
    handleError: (type: 'auth-expired' | 'other', error: Record<string, unknown>) => void
    confirm: (options: ConfirmationOptions) => Promise<boolean>
    toast: (options: ToastMessageOptions) => void
  }
  api: import('axios').AxiosInstance
  form: {
    get: () => Promise<FormState>
    submit: (data: FormData | Record<string, unknown>) => Promise<FormResult>
  }
  on: (pattern: string, callback: (event: { path?: string; message?: WsMessage }) => void) => void
}

declare global {
  interface Window {
    getWippyApi: () => Promise<WippyApi>
    $W: {
      config: () => Promise<WippyApi['config']>
      api: () => Promise<WippyApi['api']>
      form: () => Promise<WippyApi['form']>
      iframe: () => Promise<WippyApi['iframe']>
      on: () => Promise<WippyApi['on']>
    }
  }
}
```

## Example Usage

Here's a complete example of a dynamic page that integrates with Wippy:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dynamic Page</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="http://localhost:5173/proxy.js"></script>
    <script src="https://code.iconify.design/iconify-icon/2.3.0/iconify-icon.min.js"></script>
    <style>
        .loader {
            display: none;
            text-align: center;
            padding: 20px;
        }
        .content {
            display: none;
            padding: 20px;
        }
        .error {
            display: none;
            color: red;
            padding: 20px;
        }
    </style>
</head>
<body>
    <!-- Loading state -->
    <div id="loader" class="loader">
        <iconify-icon icon="tabler:loader" width="48" height="48" rotate="rotate"></iconify-icon>
        <p>Loading...</p>
    </div>

    <!-- Main content -->
    <div id="content" class="content">
        <h1>Dynamic Page</h1>
        <p id="serverText">Loading text from server...</p>
        <button id="startChatMain" class="bg-indigo-600 text-white px-4 py-2 rounded mr-2">
            <iconify-icon icon="tabler:message" class="mr-2"></iconify-icon>
            Start Chat in Main Area
        </button>
        <button id="startChatSidebar" class="bg-blue-600 text-white px-4 py-2 rounded">
            <iconify-icon icon="tabler:message" class="mr-2"></iconify-icon>
            Start Chat in Sidebar
        </button>
    </div>

    <!-- Error state -->
    <div id="error" class="error"></div>

    <script>
        // Show loader, hide other states
        document.getElementById('loader').style.display = 'block';
        document.getElementById('content').style.display = 'none';
        document.getElementById('error').style.display = 'none';

        async function initializeWippy() {
            try {
                // Method 1: Using $W global object
                const api = await $W.api();
                const iframe = await $W.iframe();
                const config = await $W.config();
                await initCustomPage(api, iframe, config);

                // Method 2: Using getWippyApi directly
                // const { api, iframe, config } = await getWippyApi();
                // await initCustomPage(api, iframe, config);
            } catch (error) {
                // Handle errors
                const errorDiv = document.getElementById('error');
                errorDiv.textContent = 'Failed to initialize: ' + error.message;
                errorDiv.style.display = 'block';
                document.getElementById('loader').style.display = 'none';

                // Report error to parent window
                const iframe = await $W.iframe();
                iframe.handleError('other', error);
            }
        }

        async function initCustomPage(api, iframe, config) {
            // Fetch data from server
            const response = await api.get('/api/some-endpoint');
            document.getElementById('serverText').textContent = response.data.text;

            // Handle sub-path if present
            if (config.path) {
                const pathInfo = document.createElement('div');
                pathInfo.className = 'mt-4 p-4 bg-gray-100 rounded';
                pathInfo.innerHTML = `
                    <p class="text-sm text-gray-600">Current sub-path: <code>${config.path}</code></p>
                    <p class="text-sm text-gray-600 mt-2">You can use this to handle different sections of your dynamic page.</p>
                `;
                document.getElementById('content').appendChild(pathInfo);
            }

            // Add click handler to start chat buttons
            document.getElementById('startChatMain').addEventListener('click', () => {
                iframe.startChat('your-start-token', false); // Open in main area
            });

            document.getElementById('startChatSidebar').addEventListener('click', () => {
                iframe.startChat('your-start-token', true); // Open in sidebar
            });

            // Show content, hide loader
            document.getElementById('loader').style.display = 'none';
            document.getElementById('content').style.display = 'block';
        }

        // Initialize when the page loads
        initializeWippy();
    </script>
</body>
</html>
```

This example demonstrates:
1. Loading the Wippy proxy script and Iconify
2. Showing a loading state while initializing
3. Fetching data from the server using the authenticated API
4. Adding buttons to start a new chat in either the main area or the sidebar
5. Proper error handling and display
6. Clean state management between loading, content, and error states

## Error Handling

The API provides built-in error handling through the `iframe.handleError` method. Use it to report:
- Authentication errors (`auth-expired`) - trigger this if Auth token has expired
- Other application errors (`other`) - trigger this for everything else

Example:
```typescript
try {
  await api.get('/protected-endpoint')
}
catch (error) {
  if (error.response?.status === 401) {
    iframe.handleError('auth-expired', error)
  }
  else {
    iframe.handleError('other', error)
  }
}
```

## Styling

Use Tailwind CSS for styling your dynamic pages. Include the Tailwind script in your HTML:

```html
<script src="https://cdn.tailwindcss.com"></script>
```

Proxy.js has embedded tailwind.config that is shipped with following additional colors:

"primary"
"secondary"
"text"
"surface"

Proxy.js has embedded primevue classes like .p-button .p-checkbox etc. Prefer using them over manual tailwind classes where possible.

## `<w-artifact>` Web Component

The proxy now exposes a native Web-Component called `<w-artifact>` that lets you embed **pages or artifacts** directly inside any dynamic page without writing Vue code.

### Basic usage

```html
<!-- Render an artifact by UUID -->
<w-artifact id="38fb…" type="artifact"></w-artifact>

<!-- Render a page and let it auto-resize -->
<w-artifact id="123e456…" type="page" auto-height></w-artifact>
```

### Attributes

| Attribute     | Required | Values                         | Default     | Description                                                                                     |
| ------------- | -------- | ------------------------------ | ----------- | ------------------------------------------------------------------------------------------------ |
| `id`          | Yes      | Artifact / Page UUID           | –           | Identifies which piece of content to load.                                                      |
| `type`        | No       | `artifact` \| `page`           | `artifact`  | Tells the component which REST endpoint to call.                                                |
| `auto-height` | No       | _(boolean flag)_               | `false`     | When present, the element listens for `CmdBodySize` events coming from its iframe and adjusts `height` automatically. |

### Events

The element dispatches standard browser `CustomEvent`s that you can listen to:

| Event name | When it fires | `detail` payload |
| ---------- | ------------- | ---------------- |
| `loading`  | Immediately before the remote content starts fetching. | – |
| `load`     | After the iframe has been inserted successfully.       | – |
| `error`    | When the fetch fails.                                  | Original error object |
| `size`     | Whenever auto-height updates the iframe size.          | `{ width: number, height: number }` |

Example:

```javascript
document.querySelector('w-artifact')?.addEventListener('error', (e) => {
  console.error('Failed to load artifact:', e.detail);
});
```

### Behaviour

1. The component fetches raw HTML using the proxy's authenticated `api` instance:
   • `type="page"` → `/api/public/pages/content/<id>`  
   • `type="artifact"` → `/api/artifact/<id>/content`

2. The HTML is rendered inside a sandboxed iframe (`sandbox="allow-same-origin allow-scripts allow-forms allow-popups"`).

3. All iframe → parent commands listed in _Parent Window Communication_ (start chat, open session, navigate, confirm, toast, subscriptions, etc.) are bridged automatically, so content behaves exactly as if it were loaded by the Vue front-end.

4. Markdown and inline-interactive artifacts are **not** supported by this component. It only handles plain iframe renders.

### Styling via CSS

`<w-artifact>` exposes its state to CSS in two ways:

1. **Host `status` attribute** – always one of `loading`, `ready`, `error`.
   ```css
   /* Fade while loading */
   w-artifact[status="loading"] { opacity: 0.5; }

   /* Red outline when failed */
   w-artifact[status="error"]  { border: 1px solid theme('colors.red.500'); }
   ```

2. **Shadow-parts** – internal nodes are labelled so you can customise them individually:

   | Part name | Node |
      | --------- | ---------------- |
   | `loader`  | The loading placeholder `<div>` |
   | `error`   | The error placeholder `<div>` |
   | `frame`   | The underlying `<iframe>` |

   ```css
   /* Larger spinner text */
   w-artifact::part(loader) { font-size: 1rem; }

   /* Hide the iframe's border */
   w-artifact::part(frame) { border: 0; }
   ```

Because these attributes/parts live on the host element, no Shadow-DOM piercing is required and Tailwind/utility classes work as usual.
