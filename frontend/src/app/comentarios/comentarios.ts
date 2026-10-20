import { Component, OnInit, inject, input, signal } from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { DatePipe } from '@angular/common';
import { ComentarioService } from '../service/comentario.service';
import { Comentario } from '../model/comentario.model';

@Component({
  imports: [FormsModule, DatePipe],
  selector: 'app-comentarios',
  styleUrl: './comentarios.css',
  templateUrl: './comentarios.html',
})
export class Comentarios {
  private comentarioService = inject(ComentarioService);

  /** ID de la tarea a la que pertenecen los comentarios (lo entrega el padre) */
  tareaId = input.required<number>();

  comentarios = signal<Comentario[]>([]);
  cargando = signal(true);
  enviando = signal(false);
  error = signal<string | null>(null);
  nuevo = '';

  ngOnInit() { this.cargar(); }

  cargar() {
    this.cargando.set(true);
    this.comentarioService.listar(this.tareaId()).subscribe({
      next: lista => { this.comentarios.set(lista); this.cargando.set(false); this.error.set(null); },
      error: e => { this.cargando.set(false); this.mostrarError(e); },
    });
  }

  agregar() {
    const texto = this.nuevo.trim();
    if (!texto || this.enviando()) return;
    this.enviando.set(true);
    this.comentarioService.crear(this.tareaId(), texto).subscribe({
      next: c => {
        // Lo agregamos arriba sin volver a pedir toda la lista
        this.comentarios.update(lista => [c, ...lista]);
        this.nuevo = '';
        this.enviando.set(false);
        this.error.set(null);
      },
      error: e => { this.enviando.set(false); this.mostrarError(e); },
    });
  }

  borrar(c: Comentario) {
    this.comentarioService.borrar(c.tareaId, c.comentarioId).subscribe({
      next: () => this.comentarios.update(lista => lista.filter(x => x.comentarioId !== c.comentarioId)),
      error: e => this.mostrarError(e),
    });
  }

  private mostrarError(e: HttpErrorResponse) {
    this.error.set(e.error?.message ?? `Error ${e.status}`);
  }
}
