import { Component, OnInit, inject, signal } from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { DatePipe } from '@angular/common';
import { TareaService } from './service/tarea.service';
import { Tarea } from './model/tarea.model';

@Component({
  selector: 'app-root',
  imports: [FormsModule, DatePipe],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App implements OnInit {
  private tareaService = inject(TareaService);

  tareas = signal<Tarea[]>([]);
  pagina = signal(1);
  hayMas = signal(false);
  error = signal<string | null>(null);
  nueva = '';

  ngOnInit() { this.cargar(); }

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
}
