# Room Reservations - Prueba Técnica

## Contexto del Proyecto

Este es un sistema de reservas de salas de reuniones. Tu tarea es implementar las reglas de negocio y la API REST siguiendo TDD.

## Stack Técnico

- **Rails 8** (API mode)
- **SQLite** (ya configurado, sin setup adicional)
- **RSpec** para testing
- **FactoryBot** para fixtures
- **Shoulda Matchers** para validaciones

## Comandos Útiles

```bash
# Ejecutar tests
bundle exec rspec

# Ejecutar un test específico
bundle exec rspec spec/models/reservation_spec.rb

# Ejecutar tests con output detallado
bundle exec rspec --format documentation

# Levantar servidor
rails server

# Consola de Rails
rails console
```

## Modelos Existentes

Los modelos ya están creados con sus migraciones:

### Room
- `name` (string) - Nombre único de la sala
- `capacity` (integer) - Capacidad máxima
- `has_projector` (boolean)
- `has_video_conference` (boolean)
- `floor` (integer)

### User
- `name` (string)
- `email` (string) - Único
- `department` (string)
- `max_capacity_allowed` (integer) - Capacidad máxima de sala que puede reservar
- `is_admin` (boolean) - Default false

### Reservation
- `room_id` (references)
- `user_id` (references)
- `title` (string)
- `starts_at` (datetime)
- `ends_at` (datetime)
- `recurring` (string) - null, 'daily', 'weekly'
- `recurring_until` (date)
- `cancelled_at` (datetime) - null si activa

## Reglas de Negocio a Implementar

### RN1: Sin solapamiento de reservas
No puede haber dos reservas activas para la misma sala en el mismo horario.

### RN2: Duración máxima de 4 horas
Una reserva no puede durar más de 4 horas.

### RN3: Solo horario laboral
Las reservas deben ser entre 9:00 y 18:00, de lunes a viernes.

### RN4: Restricción de capacidad
Usuarios normales solo pueden reservar salas con capacidad ≤ su `max_capacity_allowed`. Admins pueden reservar cualquier sala.

### RN5: Máximo 3 reservas activas
Un usuario normal no puede tener más de 3 reservas activas (futuras, no canceladas). Admins sin límite.

### RN6: Cancelación anticipada
Solo se puede cancelar una reserva si faltan más de 60 minutos para el inicio.

### RN7: Reservas recurrentes
Al crear reservas recurrentes, todas las ocurrencias deben cumplir las reglas. Si alguna falla, no se crea ninguna.

## Flujo de Trabajo TDD

1. **Escribe el test primero** - Describe el comportamiento esperado
2. **Verifica que falla** - `bundle exec rspec` debe mostrar rojo
3. **Implementa el código mínimo** - Solo lo necesario para pasar el test
4. **Verifica que pasa** - `bundle exec rspec` debe mostrar verde
5. **Refactoriza si es necesario** - Mantén los tests en verde
6. **Commit** - Un commit por cada ciclo red-green-refactor

## Ejemplo de Test

```ruby
# spec/models/reservation_spec.rb
RSpec.describe Reservation, type: :model do
  describe 'RN2: Duración máxima' do
    it 'no permite reservas de más de 4 horas' do
      reservation = build(:reservation,
        starts_at: Time.zone.parse('2024-01-15 10:00'),
        ends_at: Time.zone.parse('2024-01-15 15:00') # 5 horas
      )

      expect(reservation).not_to be_valid
      expect(reservation.errors[:base]).to include('La reserva no puede durar más de 4 horas')
    end
  end
end
```

## Tips para usar Claude Code

- Pide que genere los tests primero, luego la implementación
- Sé específico sobre los mensajes de error que quieres
- Pide que cubra edge cases
- Revisa el código generado antes de hacer commit
- Si algo no funciona, describe el error y pide corrección

## API Endpoints (a implementar)

```
GET    /api/v1/rooms
GET    /api/v1/rooms/:id
POST   /api/v1/rooms (solo admin)
GET    /api/v1/rooms/:id/availability?date=YYYY-MM-DD

GET    /api/v1/users
POST   /api/v1/users
GET    /api/v1/users/:id

GET    /api/v1/reservations
POST   /api/v1/reservations
GET    /api/v1/reservations/:id
PATCH  /api/v1/reservations/:id/cancel
```

## Estructura de Commits Esperada

```
test(room): add validation tests for Room model
feat(room): implement Room validations
test(user): add validation tests for User model
feat(user): implement User validations
test(reservation): add RN1 overlapping tests
feat(reservation): implement no-overlap validation
...
```
