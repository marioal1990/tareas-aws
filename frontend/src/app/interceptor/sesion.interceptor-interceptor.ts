import { HttpContextToken, HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { OidcSecurityService } from 'angular-auth-oidc-client';
import { catchError, switchMap, throwError } from 'rxjs';
import { SesionService } from '../service/sesion.service';

/** Marca las peticiones que ya son un reintento, para no entrar en un ciclo */
const ES_REINTENTO = new HttpContextToken<boolean>(() => false);

const RUTAS_API = ['/tareas-db/', '/comentarios-api/'];

export const sesionInterceptor: HttpInterceptorFn = (req, next) => {
  const oidc = inject(OidcSecurityService);
  const sesion = inject(SesionService);

  return next(req).pipe(
    catchError((err: HttpErrorResponse) => {
      const esApi = RUTAS_API.some(r => req.url.startsWith(r));
      if (err.status !== 401 || !esApi || req.context.get(ES_REINTENTO)) {
        return throwError(() => err);
      }

      // El token venció: renovar con el refresh token y reintentar una sola vez
      return oidc.forceRefreshSession().pipe(
        switchMap(resultado => {
          if (!resultado?.isAuthenticated || !resultado.accessToken) {
            return throwError(() => err);
          }
          return next(req.clone({
            setHeaders: { Authorization: `Bearer ${resultado.accessToken}` },
            context: req.context.set(ES_REINTENTO, true),
          }));
        }),
        catchError(errorFinal => {
          // No se pudo renovar (refresh token vencido o revocado): cerrar sesión local
          sesion.expirada();
          oidc.logoffLocal();
          return throwError(() => errorFinal);
        }),
      );
    }),
  );
};
