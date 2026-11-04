SPE CSP-2 (Three-Phase Coning), MRST / Octave, SI
================================================

Структура как в NewOil_v29_PVT_single_source:
  Input/CSP2_SI.json — ЕДИНСТВЕННЫЙ источник численных свойств
  Input/MXSPE002_SI.dat — проверенный CMG IMEX эталон (НЕ источник для MRST)
  Modules/ — расчетные модули
  Results/ — выходные данные
  Templates/ — исходный CMG FIELD deck
  CSP2_Main.m — запуск

ЗАПУСК в Octave (после инициализации MRST):
  cd('/mnt/d/MRST_Radial_ Model/MRST_CSP2_SI_full')
  CSP2_Main

Зависимости: MRST ad-core, ad-props, ad-blackoil, deckformat, MRST-compatible
Octave. Для Octave может понадобиться добавить ваши уже проверенные
обертки griddedInterpolant.m и deval.m из NewOil_v29 в Modules/.

ВАЖНО: ПАКЕТ НЕ ПРОГОНЯЛСЯ в MRST/Octave в среде подготовки.
Это реализация для первого реального запуска и отладки, а не заявленное
совпадение с CMG. Возможны несовместимости API MRST и настройки EQUIL.

Требуют проверки:
  - CMG GEOMETRY geofac=0.5 -> WI: пока приближенное Peaceman WI;
  - CMG PB=0 -> начальное Rs: в ECLIPSE создана ветвь Rs=0 и PBVD=0;
  - CMG oil compressibility CO -> undersaturated PVTO: использована
    экспоненциальная аппроксимация Bo, постоянная muO;
  - CMG трехфазная интерполяция SLT/SWT и MRST Stone model;
  - начальное капиллярно-гравитационное равновесие;
  - режим ORAT и BHP ограничения: явное переключение по расчетному BHP;
  - расхождение результатов на 900-е сутки без подгонки.

CMG reference t=900 days:
BHP=23402 kPa, Qo=15.899 sm3/d, Qw=9.5244 sm3/d,
Qg=3822.4 sm3/d, WCUT=0.37463, GOR=240.42 sm3/sm3,
Np=82217 sm3, Wp=37531 sm3, Gp=33559000 sm3.

Рекомендуемый порядок диагностики:
  1. CSP2_LoadInputs(pwd)
  2. CSP2_Main
  3. Если ошибка: прислать ПЕРВУЮ ошибку с полным стеком.
  4. Проверить начальные P/Sw/So/Sg, затем WI, затем временной шаг.

Файлы NewOil_v29 не меняются.
