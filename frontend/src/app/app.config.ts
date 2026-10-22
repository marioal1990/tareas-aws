import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { provideRouter } from '@angular/router';
import { authInterceptor, provideAuth } from 'angular-auth-oidc-client';
import { routes } from './app.routes';
import { COGNITO } from './auth.config';

export const API_URL = '/tareas-db/api/v1';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes),
    provideHttpClient(withInterceptors([authInterceptor()])),
    provideAuth({
      config: {
        authority: COGNITO.issuer,
        clientId: COGNITO.clientId,
        redirectUrl: window.location.origin + '/',
        postLogoutRedirectUri: window.location.origin + '/',
        scope: 'openid email profile',
        responseType: 'code',
        silentRenew: true,
        useRefreshToken: true,
        // Solo estas rutas reciben el header Authorization
        secureRoutes: ['/tareas-db/', '/comentarios-api/'],
      },
    }),
  ]
};
