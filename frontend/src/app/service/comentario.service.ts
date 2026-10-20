import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { Comentario } from '../model/comentario.model';
import { ControllerResponse } from '../model/tarea.model';

@Injectable({ providedIn: 'root' })
export class ComentarioService {
  private http = inject(HttpClient);
  private url = (tareaId: number) => `/comentarios-api/tareas/${tareaId}/comentarios`;

  listar(tareaId: number): Observable<Comentario[]> {
    return this.http.get<ControllerResponse<Comentario[]>>(this.url(tareaId)).pipe(map(r => r.data));
  }

  crear(tareaId: number, texto: string): Observable<Comentario> {
    return this.http.post<ControllerResponse<Comentario>>(this.url(tareaId), { texto }).pipe(map(r => r.data));
  }

  borrar(tareaId: number, comentarioId: string): Observable<void> {
    return this.http.delete<void>(`${this.url(tareaId)}/${comentarioId}`);
  }
}
