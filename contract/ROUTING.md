# [ROUTING & DATA CONTRACT: Archivator_Agent] (V1.0)

**CONTRACT_ID:** CTL-ARCH-ROUTING-01
**AUTHORITY:** Sentinel-Guard (GUARD-01) Verification Required

## КАНАЛЫ ДОСТУПА (MEMORY ACCESS):
- `READ/WRITE`: `work/Archivator_Agent/data/` (Глобальные архивы)
- `READ/WRITE`: `work/Archivator_Agent/matrix/` (Семантические связи)
- `READ/WRITE`: `work/Archivator_Agent/memory/` (Фронтальные слепки памяти)
- `READ`: `work/*/chronolog/` (Доступ на чтение истории всех узлов)

## ПРАВИЛА УПРАВЛЕНИЯ ПАМЯТЬЮ:
1. Любой файл, попадающий в архив, должен получить уникальный хеш-идентификатор.
2. Архивариус обязан поддерживать зеркало критических файлов в `Storage/ByFile/`.
3. Запрещено удалять данные без явной директивы Капитана и верификации Стража.

**MONOPOLY:** Только Archivator_Agent имеет право на агрегацию и глобальную индексацию `data/` по всей экосистеме.
