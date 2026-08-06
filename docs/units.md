# Measurement Units: US Customary / British Imperial and Metric (SI)

Canonical reference for the unit-converter plugin. It drives the built-in `en` and `ru`
dictionaries and gives the **full picture** of every unit the plugin aims to support.

**Columns**

- **Unit** — canonical English name.
- **English forms** — every spelled word form (singular, plural, common variants) for the `en`
  dictionary.
- **Russian forms** — the full declension paradigm (all six cases, singular + plural) for the
  `ru` dictionary.
- **Symbols** — every abbreviation / typographic symbol. Symbols are **digit-gated** at scan
  time (`6 ft`, never bare `ft`); spelled forms match standalone (see `spec.md` §3.2).
- **SI equivalent** — conversion to the SI base unit. Exact values are marked *(exact)*;
  others are rounded.

**Notes**

- Direction is always **opposite system**: customary/imperial → metric and metric → customary.
- Where US and British Imperial diverge (volume, some mass), **both** variants are listed; the
  plugin shows all variants in the popup — no region detection (see `spec.md` §4.2).
- This reference lists the full picture. The **shipped** dictionaries may omit units whose word
  is common in prose but rarely a unit (`are`, `rod`, …) per the inclusion rule (`spec.md` §4.1).

---

## 1. US Customary / British Imperial Units

### 1.1 Length

| Unit | English forms | Russian forms | Symbols | SI equivalent |
|---|---|---|---|---|
| Thou (mil) | thou, thous, mil, mils | мил, мила, милу, милом, миле, милы, милов, милам, милами, милах | mil, thou | 0.0254 mm *(exact)* = 25.4 µm |
| Inch | inch, inches | дюйм, дюйма, дюйму, дюймом, дюйме, дюймы, дюймов, дюймам, дюймами, дюймах | in, ″, " | 25.4 mm *(exact)* = 2.54 cm |
| Hand | hand, hands | хэнд, хэнда, хэнду, хэндом, хэнде, хэнды, хэндов, хэндам, хэндами, хэндах; ладонь, ладони | hh, hand | 101.6 mm *(exact)* = 10.16 cm |
| Foot | foot, feet | фут, фута, футу, футом, футе, футы, футов, футам, футами, футах | ft, ′, ' | 0.3048 m *(exact)* = 30.48 cm |
| Yard | yard, yards | ярд, ярда, ярду, ярдом, ярде, ярды, ярдов, ярдам, ярдами, ярдах | yd | 0.9144 m *(exact)* |
| Fathom | fathom, fathoms | фатом, фатома, фатому, фатомом, фатоме, фатомы, фатомов, фатомам, фатомами, фатомах; сажень, сажени, саженью, саженей, саженям, саженями, саженях | ftm, fath | 1.8288 m *(exact)* |
| Rod (pole, perch) | rod, rods, pole, poles, perch, perches | род, рода, роду, родом, роде, роды, родов, родам, родами, родах; перч; поль | rd, pole, perch | 5.0292 m *(exact)* |
| Chain | chain, chains | чейн, чейна, чейну, чейном, чейне, чейны, чейнов, чейнам, чейнами, чейнах | ch | 20.1168 m *(exact)* |
| Furlong | furlong, furlongs | фурлонг, фурлонга, фурлонгу, фурлонгом, фурлонге, фурлонги, фурлонгов, фурлонгам, фурлонгами, фурлонгах | fur | 201.168 m *(exact)* |
| Mile (statute) | mile, miles | миля, мили, миле, милю, милей, милею, миль, милям, милями, милях | mi | 1609.344 m *(exact)* = 1.609344 km |
| League (land) | league, leagues | лига, лиги, лиге, лигу, лигой, лигою, лиг, лигам, лигами, лигах | lea | 4828.032 m *(exact)* ≈ 4.828 km |
| Nautical mile | nautical mile, nautical miles | морская миля, морской мили, морскую милю, морские мили, морских миль, морскими милями | nmi, NM, M | 1852 m *(exact)* = 1.852 km |
| Cable length | cable, cables | кабельтов, кабельтова, кабельтову, кабельтовом, кабельтовы, кабельтовых | cbl, cable | 185.2 m *(exact)* |

### 1.2 Area

| Unit | English forms | Russian forms | Symbols | SI equivalent |
|---|---|---|---|---|
| Square inch | square inch, square inches | квадратный дюйм, квадратного дюйма, квадратных дюймов, квадратные дюймы | sq in, in² | 6.4516 cm² *(exact)* = 645.16 mm² |
| Square foot | square foot, square feet | квадратный фут, квадратного фута, квадратных футов, квадратные футы | sq ft, ft² | 0.09290304 m² *(exact)* ≈ 929.03 cm² |
| Square yard | square yard, square yards | квадратный ярд, квадратного ярда, квадратных ярдов, квадратные ярды | sq yd, yd² | 0.83612736 m² *(exact)* |
| Rood | rood, roods | руд, руда, руду, рудом, руде, руды, рудов, рудам, рудами, рудах | rood | 1011.7141 m² ≈ 0.1012 ha |
| Acre | acre, acres | акр, акра, акру, акром, акре, акры, акров, акрам, акрами, акрах | ac | 4046.8564 m² ≈ 0.404686 ha |
| Square mile | square mile, square miles | квадратная миля, квадратной мили, квадратных миль, квадратные мили | sq mi, mi² | 2.589988 km² *(exact def.)* = 259.0 ha |

### 1.3 Volume

Values diverge by region — US and Imperial columns are both shown.

| Unit | English forms | Russian forms | Symbols | SI (US) | SI (Imperial) |
|---|---|---|---|---|---|
| Fluid ounce | fluid ounce, fluid ounces | жидкая унция, жидкой унции, жидких унций, жидкие унции | fl oz | 29.5735 mL | 28.4131 mL |
| Gill | gill, gills | джилл, джилла, джиллу, джиллом, джилле, джиллы, джиллов; гилл | gi | 118.294 mL | 142.065 mL |
| Pint | pint, pints | пинта, пинты, пинте, пинту, пинтой, пинт, пинтам, пинтами, пинтах | pt | 473.176 mL | 568.261 mL |
| Quart | quart, quarts | кварта, кварты, кварте, кварту, квартой, кварт, квартам, квартами, квартах | qt | 946.353 mL | 1.13652 L |
| Gallon | gallon, gallons | галлон, галлона, галлону, галлоном, галлоне, галлоны, галлонов, галлонам, галлонами, галлонах | gal | 3.785412 L | 4.54609 L |
| Peck | peck, pecks | пек, пека, пеку, пеком, пеке, пеки, пеков, пекам, пеками, пеках | pk | 8.80977 L | 9.09218 L |
| Bushel | bushel, bushels | бушель, бушеля, бушелю, бушелем, бушеле, бушели, бушелей, бушелям, бушелями, бушелях | bu | 35.2391 L | 36.3687 L |
| Barrel (oil) | barrel, barrels | баррель, барреля, баррелю, баррелем, барреле, баррели, баррелей, баррелям, баррелями, баррелях | bbl | 158.987 L | 158.987 L |
| Cubic inch | cubic inch, cubic inches | кубический дюйм, кубического дюйма, кубических дюймов | cu in, in³ | 16.387064 mL *(exact)* | 16.387064 mL *(exact)* |
| Cubic foot | cubic foot, cubic feet | кубический фут, кубического фута, кубических футов | cu ft, ft³ | 28.316846 L *(exact)* | 28.316846 L *(exact)* |

### 1.4 Mass / weight

| Unit | English forms | Russian forms | Symbols | SI equivalent |
|---|---|---|---|---|
| Grain | grain, grains | гран, грана, грану, граном, гране, граны, гранов, гранам, гранами, гранах | gr | 64.79891 mg *(exact)* |
| Dram | dram, drams | драхма, драхмы, драхме, драхму, драхмой, драхм, драхмам, драхмами, драхмах | dr | 1.7718452 g *(exact)* |
| Ounce | ounce, ounces | унция, унции, унцию, унцией, унциею, унций, унциям, унциями, унциях | oz | 28.349523 g *(exact)* |
| Troy ounce | troy ounce, troy ounces | тройская унция, тройской унции, тройских унций | oz t, ozt | 31.1034768 g *(exact)* |
| Pound | pound, pounds | фунт, фунта, фунту, фунтом, фунте, фунты, фунтов, фунтам, фунтами, фунтах | lb, lbs, ℔ | 453.59237 g *(exact)* ≈ 0.453592 kg |
| Stone | stone, stones | стоун, стоуна, стоуну, стоуном, стоуне, стоуны, стоунов, стоунам, стоунами, стоунах; стон | st | 6.35029318 kg *(exact)* |
| Quarter | quarter, quarters | квартер, квартера, квартеру, квартером, квартере, квартеры, квартеров | qr | 12.7005864 kg *(exact)* |
| Hundredweight | hundredweight, hundredweights | центнер, центнера, центнеров (заимств.); хандредвейт | cwt | 50.802345 kg (long) / 45.359237 kg (short) |
| Long ton | long ton, long tons, ton, tons | длинная тонна, длинной тонны, длинных тонн | LT, lt | 1016.0469 kg *(exact)* |
| Short ton | short ton, short tons, ton, tons | короткая тонна, короткой тонны, коротких тонн | ST, sh tn | 907.18474 kg *(exact)* |

### 1.5 Temperature

| Unit | English forms | Russian forms | Symbols | SI equivalent |
|---|---|---|---|---|
| Fahrenheit | degree Fahrenheit, degrees Fahrenheit, Fahrenheit | градус Фаренгейта, градуса Фаренгейта, градусов Фаренгейта, градусам Фаренгейта | °F, F | °C = (°F − 32) × 5⁄9 |

### 1.6 Speed

| Unit | English forms | Russian forms | Symbols | SI equivalent |
|---|---|---|---|---|
| Mile per hour | mile per hour, miles per hour | миля в час, мили в час, миль в час | mph, mi/h | 1.609344 km/h *(exact)* |
| Foot per second | foot per second, feet per second | фут в секунду, фута в секунду, футов в секунду | ft/s, fps | 0.3048 m/s *(exact)* |
| Knot | knot, knots | узел, узла, узлу, узлом, узле, узлы, узлов, узлам, узлами, узлах | kn, kt | 1.852 km/h *(exact)* |

### 1.7 Pressure / other

| Unit | English forms | Russian forms | Symbols | SI equivalent |
|---|---|---|---|---|
| Pound per square inch | pound per square inch, pounds per square inch | фунт на квадратный дюйм, фунтов на квадратный дюйм | psi | 6894.757 Pa ≈ 6.895 kPa |
| Horsepower (mechanical) | horsepower | лошадиная сила, лошадиной силы, лошадиных сил, лошадиными силами | hp | 745.699872 W ≈ 0.7457 kW |

---

## 2. Metric (SI) Units

The metric side is converted the **opposite** way (metric → customary/imperial). Values below
relate each unit to its SI base.

### 2.1 Length

| Unit | English forms | Russian forms | Symbols | SI value |
|---|---|---|---|---|
| Millimetre | millimetre, millimetres, millimeter, millimeters | миллиметр, миллиметра, миллиметру, миллиметром, миллиметре, миллиметры, миллиметров, миллиметрам, миллиметрами, миллиметрах | mm, мм | 0.001 m |
| Centimetre | centimetre, centimetres, centimeter, centimeters | сантиметр, сантиметра, сантиметру, сантиметром, сантиметре, сантиметры, сантиметров, сантиметрам, сантиметрами, сантиметрах | cm, см | 0.01 m |
| Decimetre | decimetre, decimetres, decimeter, decimeters | дециметр, дециметра, дециметру, дециметром, дециметре, дециметры, дециметров, дециметрам, дециметрами, дециметрах | dm, дм | 0.1 m |
| Metre | metre, metres, meter, meters | метр, метра, метру, метром, метре, метры, метров, метрам, метрами, метрах | m, м | 1 m (base) |
| Kilometre | kilometre, kilometres, kilometer, kilometers | километр, километра, километру, километром, километре, километры, километров, километрам, километрами, километрах | km, км | 1000 m |
| Micrometre (micron) | micrometre, micrometres, micron, microns | микрометр, микрометра; микрон, микрона, микрону, микроном, микроне, микроны, микронов, микронам, микронами, микронах | µm, мкм | 1e−6 m |

### 2.2 Area

| Unit | English forms | Russian forms | Symbols | SI value |
|---|---|---|---|---|
| Square centimetre | square centimetre, square centimetres | квадратный сантиметр, квадратного сантиметра, квадратных сантиметров | cm², см² | 1e−4 m² |
| Square metre | square metre, square metres | квадратный метр, квадратного метра, квадратных метров | m², м² | 1 m² |
| Are | are, ares | ар, ара, ару, аром, аре, ары, аров, арам, арами, арах; сотка, сотки, соток | a, а | 100 m² |
| Hectare | hectare, hectares | гектар, гектара, гектару, гектаром, гектаре, гектары, гектаров, гектарам, гектарами, гектарах | ha, га | 10 000 m² |
| Square kilometre | square kilometre, square kilometres | квадратный километр, квадратного километра, квадратных километров | km², км² | 1e6 m² |

### 2.3 Volume

| Unit | English forms | Russian forms | Symbols | SI value |
|---|---|---|---|---|
| Millilitre | millilitre, millilitres, milliliter, milliliters | миллилитр, миллилитра, миллилитру, миллилитром, миллилитре, миллилитры, миллилитров, миллилитрам, миллилитрами, миллилитрах | mL, ml, мл | 1e−3 L |
| Centilitre | centilitre, centilitres, centiliter, centiliters | сантилитр, сантилитра, сантилитру, сантилитром, сантилитре, сантилитры, сантилитров | cL, cl, сл | 1e−2 L |
| Litre | litre, litres, liter, liters | литр, литра, литру, литром, литре, литры, литров, литрам, литрами, литрах | L, l, л | 1 L = 1e−3 m³ |
| Cubic centimetre | cubic centimetre, cubic centimetres | кубический сантиметр, кубического сантиметра, кубических сантиметров | cm³, cc, см³ | 1 mL |
| Cubic metre | cubic metre, cubic metres | кубический метр, кубического метра, кубических метров | m³, м³ | 1000 L |

### 2.4 Mass

| Unit | English forms | Russian forms | Symbols | SI value |
|---|---|---|---|---|
| Milligram | milligram, milligrams, milligramme, milligrammes | миллиграмм, миллиграмма, миллиграмму, миллиграммом, миллиграмме, миллиграммы, миллиграммов, миллиграммам, миллиграммами, миллиграммах | mg, мг | 1e−6 kg |
| Gram | gram, grams, gramme, grammes | грамм, грамма, грамму, граммом, грамме, граммы, граммов, грамм, граммам, граммами, граммах | g, г | 1e−3 kg |
| Kilogram | kilogram, kilograms, kilogramme, kilogrammes | килограмм, килограмма, килограмму, килограммом, килограмме, килограммы, килограммов, килограмм, килограммам, килограммами, килограммах | kg, кг | 1 kg (base) |
| Quintal (metric centner) | quintal, quintals | центнер, центнера, центнеру, центнером, центнере, центнеры, центнеров, центнерам, центнерами, центнерах | q, ц | 100 kg |
| Tonne (metric ton) | tonne, tonnes, metric ton, metric tons | тонна, тонны, тонне, тонну, тонной, тонн, тоннам, тоннами, тоннах | t, т | 1000 kg |

### 2.5 Temperature

| Unit | English forms | Russian forms | Symbols | SI value |
|---|---|---|---|---|
| Celsius | degree Celsius, degrees Celsius, Celsius, centigrade | градус Цельсия, градуса Цельсия, градусов Цельсия | °C | °F = °C × 9⁄5 + 32 |
| Kelvin | kelvin, kelvins | кельвин, кельвина, кельвину, кельвином, кельвине, кельвины, кельвинов, кельвинам, кельвинами, кельвинах | K, К | °C = K − 273.15 |

### 2.6 Speed

| Unit | English forms | Russian forms | Symbols | SI value |
|---|---|---|---|---|
| Metre per second | metre per second, metres per second, meter per second, meters per second | метр в секунду, метра в секунду, метров в секунду | m/s, м/с | base |
| Kilometre per hour | kilometre per hour, kilometres per hour, kilometer per hour, kilometers per hour | километр в час, километра в час, километров в час | km/h, kph, км/ч | 0.277778 m/s |

### 2.7 Pressure / other

| Unit | English forms | Russian forms | Symbols | SI value |
|---|---|---|---|---|
| Pascal | pascal, pascals | паскаль, паскаля, паскалю, паскалем, паскале, паскали, паскалей, паскалям, паскалями, паскалях | Pa, Па | 1 Pa (base) |
| Kilopascal | kilopascal, kilopascals | килопаскаль, килопаскаля, килопаскалю, килопаскалем, килопаскале, килопаскали, килопаскалей | kPa, кПа | 1000 Pa |
| Bar | bar, bars | бар, бара, бару, баром, баре, бары, баров, барам, барами, барах | bar, бар | 100 000 Pa |
| Watt | watt, watts | ватт, ватта, ватту, ваттом, ватте, ватты, ваттов, ватт, ваттам, ваттами, ваттах | W, Вт | 1 W (base) |
| Kilowatt | kilowatt, kilowatts | киловатт, киловатта, киловатту, киловаттом, киловатте, киловатты, киловаттов | kW, кВт | 1000 W |

---

## 3. Quick conversion factors (customary/imperial → metric)

```
Length
  1 inch          = 25.4 mm            (exact)
  1 foot          = 0.3048 m           (exact)
  1 yard          = 0.9144 m           (exact)
  1 fathom        = 1.8288 m           (exact)
  1 rod           = 5.0292 m           (exact)
  1 chain         = 20.1168 m          (exact)
  1 furlong       = 201.168 m          (exact)
  1 mile          = 1.609344 km        (exact)
  1 league        = 4.828032 km        (exact)
  1 nautical mile = 1.852 km           (exact)

Area
  1 sq inch       = 6.4516 cm²         (exact)
  1 sq foot       = 0.09290304 m²      (exact)
  1 sq yard       = 0.83612736 m²      (exact)
  1 acre          = 0.40468564 ha
  1 sq mile       = 2.589988 km²

Volume (US | Imperial)
  1 fluid ounce   = 29.5735 mL | 28.4131 mL
  1 pint          = 0.473176 L | 0.568261 L
  1 quart         = 0.946353 L | 1.13652 L
  1 gallon        = 3.785412 L | 4.54609 L
  1 bushel        = 35.2391 L  | 36.3687 L
  1 barrel (oil)  = 158.987 L

Mass
  1 grain         = 64.79891 mg        (exact)
  1 ounce         = 28.349523 g        (exact)
  1 troy ounce    = 31.1034768 g       (exact)
  1 pound         = 0.45359237 kg      (exact)
  1 stone         = 6.35029318 kg      (exact)
  1 long ton      = 1016.0469 kg       (exact)
  1 short ton     = 907.18474 kg       (exact)

Temperature / Speed / Power
  °C              = (°F − 32) × 5⁄9
  1 mph           = 1.609344 km/h      (exact)
  1 ft/s          = 0.3048 m/s         (exact)
  1 knot          = 1.852 km/h         (exact)
  1 hp (mech.)    = 745.699872 W
```
