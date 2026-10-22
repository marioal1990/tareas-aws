import { Injectable, signal } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class SesionService {
  /** Mensaje a mostrar cuando la sesión no se pudo renovar */
  readonly aviso = signal<string | null>(null);

  expirada() {
    this.aviso.set('Tu sesión expiró. Inicia sesión nuevamente para continuar.');
  }

  limpiar() {
    this.aviso.set(null);
  }
}
