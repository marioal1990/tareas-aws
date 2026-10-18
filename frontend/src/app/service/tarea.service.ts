import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { API_URL } from '../app.config';
import { ControllerResponse, PageResponse, Tarea } from '../model/tarea.model';

@Injectable({ providedIn: 'root' })
export class TareaService {
  private http = inject(HttpClient);
  private url = `${API_URL}/tareas`;

  listar(page = 1, size = 10): Observable<PageResponse<Tarea>> {
    const params = new HttpParams().set('page', page).set('size', size).set('sort', 'creadaEn,desc');
    return this.http
      .get<ControllerResponse<PageResponse<Tarea>>>(this.url, { params })
      .pipe(map(r => r.data));
  }

  crear(titulo: string): Observable<Tarea> {
    return this.http
      .post<ControllerResponse<Tarea>>(this.url, { titulo, completada: false })
      .pipe(map(r => r.data));
  }

  borrar(id: number): Observable<void> {
    return this.http.delete<void>(`${this.url}/${id}`);
  }
}
