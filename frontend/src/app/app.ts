import { Component, OnInit, inject, signal } from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { DatePipe } from '@angular/common';
import { TareaService } from './service/tarea.service';
import { Tarea } from './model/tarea.model';
import { Comentarios } from './comentarios/comentarios';
import { OidcSecurityService } from 'angular-auth-oidc-client';
import { COGNITO } from './auth.config';

@Component({
  selector: 'app-root',
  imports: [FormsModule, DatePipe, Comentarios],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App implements OnInit {
  private tareaService = inject(TareaService);

  //INICIAR SESION - COGNITO
  private oidc = inject(OidcSecurityService);

  tareas = signal<Tarea[]>([]);
  pagina = signal(1);
  hayMas = signal(false);
  error = signal<string | null>(null);
  nueva = '';

  /** ID de la tarea con los comentarios desplegados (solo una a la vez) */
  comentariosAbiertos = signal<number | null>(null);

  //INICIAR SESION - COGNITO
  autenticado = signal(false);
  email = signal<string | null>(null);

  ngOnInit() {
    // Procesa el regreso desde Cognito (?code=...) o recupera una sesión existente
    this.oidc.checkAuth().subscribe(({ isAuthenticated, userData }) => {
      this.autenticado.set(isAuthenticated);
      this.email.set(userData?.email ?? null);
      if (isAuthenticated) this.cargar();
    });
  }

  cargar() {
    this.tareaService.listar(this.pagina()).subscribe({
      next: p => { this.tareas.set(p.content); this.hayMas.set(p.hasNext); this.error.set(null); },
      error: e => this.mostrarError(e),
    });
  }

  agregar() {
    const titulo = this.nueva.trim();
    if (!titulo) return;
    this.tareaService.crear(titulo).subscribe({
      next: () => { this.nueva = ''; this.pagina.set(1); this.cargar(); },
      error: e => this.mostrarError(e),
    });
  }

  alternar(t: Tarea) {
    this.tareaService.cambiarCompletada(t.id!, !t.completada).subscribe({
      next: () => this.cargar(),
      error: e => this.mostrarError(e),
    });
  }

  borrar(id: number) {
    this.tareaService.borrar(id).subscribe({
      next: () => this.cargar(),
      error: e => this.mostrarError(e),
    });
  }

  cambiarPagina(delta: number) {
    this.pagina.update(p => p + delta);
    this.cargar();
  }

  private mostrarError(e: HttpErrorResponse) {
    this.error.set(e.error?.message ?? `Error ${e.status}`);
  }

  /**
   * Alterna la visibilidad de los comentarios de una tarea. Si ya están visibles, los oculta; si no lo están, los muestra.
   * Solo se permite que los comentarios de una tarea estén visibles a la vez.
   * @param id ID de la tarea cuyos comentarios se quieren mostrar u ocultar
   */
  toggleComentarios(id: number) {
    this.comentariosAbiertos.update(actual => (actual === id ? null : id));
  }

  //INICIAR SESION - COGNITO
  login() {
    this.oidc.authorize();
  }

  logout() {
    // Cognito no publica el endpoint de logout estándar: se cierra la sesión local y luego la de Cognito
    this.oidc.logoffLocal();
    const volver = encodeURIComponent(window.location.origin + '/');
    window.location.href = `${COGNITO.dominio}/logout?client_id=${COGNITO.clientId}&logout_uri=${volver}`;
  }
}
