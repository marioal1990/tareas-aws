export interface Tarea {
  id?: number;
  titulo: string;
  completada: boolean;
  creadaEn?: string;
}

export interface PageResponse<T> {
  content: T[];
  page: number;
  size: number;
  hasNext: boolean;
}

export interface ControllerResponse<T> {
  code: number;
  message: string;
  data: T;
}
