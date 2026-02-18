# Migración de Estructura SpainInside_WEB a DatqBox Administrativo

## ✅ Cambios Realizados

He migrado completamente la estructura de autenticación, menú, componentes y store de SpainInside_WEB a tu proyecto DatqBox, respetando la estructura actual y adaptándola a tu API local.

### 1. **Autenticación con NextAuth** ✨
- **Nuevo archivo:** `auth.ts` - Configuración de NextAuth con Provider Credentials
- **Nuevo archivo:** `middleware.ts` - Middleware de protección de rutas
- **Nueva carpeta:** `src/app/authentication/` con:
  - `AuthContext.tsx` - Context para manejar estado de autenticación
  - `config.ts` - Configuración de rutas públicas
  - `layout.tsx` - Layout para páginas de autenticación
  - `auth/AuthLogin.tsx` - Componente de login mejorado con validación

### 2. **Store Global con Zustand** 📦
- **Nuevo archivo:** `src/app/store/useStore.ts`
- Maneja estado global de usuario, permisos y UI
- Métodos para actualizar información del usuario
- Estado para sidebar colapsado/expandido

### 3. **Providers Mejorados** 🔧
- **Actualizado:** `AppProviders.tsx` con:
  - `SessionProvider` de NextAuth
  - `AuthProvider` personalizado
  - `QueryProvider` para @tanstack/react-query
  - `ToastProvider` para notificaciones
  - `ThemeProvider` de MUI
  - `Toaster` de react-hot-toast
- **Nuevo:** `ToastProvider.tsx` para notificaciones con Snackbars

### 4. **Panel de Dashboard Completo** 🎨
- **Actualizado:** `src/app/(dashboard)/layout.tsx` con:
  - Sidebar colapsable/expandible
  - Responsive para móvil
  - Protección de rutas
  - Navegación mejorada con submenús
- **Nuevos componentes:**
  - `AppBarWrapper.tsx` - AppBar personalizado
  - `SidebarFooterAccount.tsx` - Menú de usuario con logout
- **Nuevo:** `src/app/(dashboard)/page.tsx` - Dashboard home

### 5. **Sistema de Menú Avanzado** 📂
- **Nuevo archivo:** `src/lib/menuConfig.ts` (configurable y escalable)
  - Definición centralizada del menú
  - Soporte para roles (admin/user)
  - Estructura anidada de items
  - Iconos dinámicos
- **Nuevo componente:** `src/components/Navigation/NavigationMenu.tsx`
  - Navegación recursiva
  - Submenús expandibles
  - Indicadores de ruta activa

### 6. **UI/UX Mejorado**
- **Nuevo:** `src/app/(dashboard)/shared/logo/Logo.tsx` - Logo de marca
- **Variables de ambiente:** `.env.local` con configuración

## 📋 Dependencias Instaladas

```json
{
  "next-auth": "^5.0.0-beta.25",
  "zustand": "^5.0.3",
  "react-hook-form": "^7.54.2",
  "@hookform/resolvers": "^3.10.0",
  "zod": "^3.24.1",
  "axios": "^1.7.9",
  "react-hot-toast": "^2.5.1"
}
```

## 🚀 Cómo Usar

### 1. Instalar nuevas dependencias
```bash
cd frontend
npm install
# O si usas el workspace raíz
npm install --workspaces
```

### 2. Configurar variables de entorno
Edita `frontend/.env.local`:
```env
NEXT_PUBLIC_BACKEND_URL=http://localhost:3001
AUTH_SECRET=tu-clave-segura-aqui
```

### 3. Ejecutar el proyecto
```bash
# Desarrollo completo (API + Frontend)
npm run dev

# Solo frontend
npm run dev:web

# Solo API
npm run dev:api
```

## 🔐 Flujo de Autenticación

1. Usuario accede a `/authentication/login`
2. Ingresa credenciales (usuario/contraseña)
3. AuthLogin usa `signIn()` de NextAuth con provider Credentials
4. Se hace POST a `{BACKEND_URL}/v1/auth/login` (tu API actual)
5. Backend retorna usuario + token
6. NextAuth almacena sesión
7. AuthContext actualiza estado global
8. Usuario es redirigido a `/`

## 📁 Estructura de Carpetas

```
frontend/
├── auth.ts                          # NextAuth config
├── middleware.ts                    # Route protection
├── src/
│   ├── app/
│   │   ├── authentication/          # NEW: Auth pages
│   │   │   ├── auth/
│   │   │   │   └── AuthLogin.tsx
│   │   │   ├── login/
│   │   │   │   └── page.tsx
│   │   │   ├── AuthContext.tsx
│   │   │   ├── config.ts
│   │   │   └── layout.tsx
│   │   ├── (dashboard)/             # Protected routes
│   │   │   ├── AppBarWrapper.tsx
│   │   │   ├── SidebarFooterAccount.tsx
│   │   │   ├── layout.tsx           # UPDATED
│   │   │   ├── page.tsx             # NEW
│   │   │   └── shared/
│   │   │       └── logo/
│   │   │           └── Logo.tsx
│   │   ├── store/
│   │   │   └── useStore.ts          # NEW: Zustand store
│   │   ├── layout.tsx
│   │   └── page.tsx
│   ├── components/
│   │   └── Navigation/
│   │       └── NavigationMenu.tsx    # NEW
│   ├── lib/
│   │   └── menuConfig.ts            # NEW
│   └── providers/
│       ├── AppProviders.tsx         # UPDATED
│       └── ToastProvider.tsx        # NEW
└── .env.local                       # NEW
```

## 🎯 Próximos Pasos

1. **Adaptar módulos existentes:**
   - Los módulos actuales (facturas, inventario, etc.) funcionan igual
   - Ahora están protegidos por autenticación
   - Pueden usar el store global con `useStore()`

2. **Extender funcionalidades:**
   - Agregar más roles/permisos en `roles.ts`
   - Expandir menú en `menuConfig.ts`
   - Crear páginas de admin si es necesario

3. **Mejorar integraciones:**
   - El store puede usarse en cualquier componente
   - Los toasts están disponibles globalmente
   - La autenticación está centralizada

## 🔌 Cómo Integrar con Tus Módulos

### 1. Usar datos del usuario en componentes
```tsx
'use client';
import { useAuth } from '@/app/authentication/AuthContext';

export default function MyComponent() {
  const { userName, isAdmin, accessToken } = useAuth();
  
  return <div>Bienvenido, {userName}</div>;
}
```

### 2. Usar el store global
```tsx
'use client';
import { useStore } from '@/app/store/useStore';

export default function MyComponent() {
  const { userName, toggleSidebar } = useStore();
  
  return <button onClick={toggleSidebar}>Toggle Sidebar</button>;
}
```

### 3. Mostrar notificaciones
```tsx
import toast from 'react-hot-toast';

export default function MyComponent() {
  const handleClick = () => {
    toast.success('¡Éxito!');
    // o toast.error('Error'), toast.loading('Cargando...')
  };
}
```

## ✨ Características Principales

✅ Autenticación con NextAuth (Credentials Provider)
✅ Protección de rutas automática con middleware
✅ Context API + Zustand para estado global
✅ Sidebar colapsable y responsive
✅ Menú con submenús expandibles
✅ Sistema de notificaciones con Toast
✅ Logout seguro
✅ Perfil de usuario en sidebar
✅ Soporte para roles (admin/user)
✅ Login page personalizada con validación
✅ React Hook Form + Zod para validación

## 🐛 Troubleshooting

**Error: "AUTH_SECRET no está definido"**
- Asegúrate de tener definida la variable `AUTH_SECRET` en `.env.local`

**Error: "NEXT_PUBLIC_BACKEND_URL"**
- Verifica que tu backend está corriendo en http://localhost:3001
- Actualiza la URL según tu configuración

**Login no funciona**
- Revisa la consola (F12) para ver el error exacto
- Verifica en Network que la petición a `/v1/auth/login` se está haciendo
- Comprueba que tu backend responde correctamente con usuario + token

**Estilos no se aplican**
- Ejecuta `npm install` para asegurar que MUI está instalado
- Reinicia el servidor de development
