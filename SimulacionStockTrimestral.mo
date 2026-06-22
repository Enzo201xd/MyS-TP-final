model SimulacionStockMensual
  // ==========================================
  // PARÁMETROS DE ALEATORIZACIÓN
  // ==========================================
  parameter Modelica.Units.SI.Period samplePeriod = 1 
    "Periodo de recambio (1 = un mes)";

  parameter Integer globalSeed = 30020
    "Semilla global para los generadores";

  parameter Integer localSeedLib = 614657
    "Semilla local para el ruido de Libreria";

  parameter Integer localSeedPresto = 918273
    "Semilla local para el ruido de Prestobarbas";

  parameter Real sigma_lib = 150 "Desviacion estandar para ruido de libreria";
  parameter Real sigma_presto = 50 "Desviacion estandar para ruido de prestobarbas";

  // ==========================================
  // PARÁMETROS DE STOCK (Fijos, de tus tablas)
  // ==========================================
  parameter Real libreria_rvc_min = 1.266;
  parameter Real libreria_rvc_max = 6.549;
  parameter Real libreria_stock_max = 3905;
  parameter Real libreria_costo_base = 100;
  
  parameter Real presto_rvc_min = 1.230;
  parameter Real presto_rvc_max = 5.405;
  parameter Real presto_stock_max = 600;
  parameter Real presto_costo_base = 150;

  // ==========================================
  // VARIABLES ALEATORIAS (Ruido Mensual)
  // ==========================================
  discrete Real ruido_libreria(start = 0, fixed = true);
  discrete Real ruido_presto(start = 0, fixed = true);
  
  discrete output Real r1024_lib(start = 0, fixed = true);
  discrete output Real r1024_presto(start = 0, fixed = true);

  discrete Integer state1024_lib[33](each start = 0, each fixed = true);
  discrete Integer state1024_presto[33](each start = 0, each fixed = true);

  // ==========================================
  // VARIABLES DEL SISTEMA (Cambian mes a mes)
  // ==========================================
  Real libreria_consumo;
  Real libreria_rvc;
  Real libreria_precio_venta;
  Real libreria_compra_mensual;

  Real presto_consumo;
  Real presto_rvc;
  Real presto_precio_venta;
  Real presto_compra_mensual;

algorithm
  // ==========================================
  // GENERACIÓN DE RUIDO (Estructura Xorshift1024star)
  // ==========================================
  when initial() then
    // Inicializamos estados
    state1024_lib := Modelica.Math.Random.Generators.Xorshift1024star.initialState(localSeedLib, globalSeed);
    state1024_presto := Modelica.Math.Random.Generators.Xorshift1024star.initialState(localSeedPresto, globalSeed);

    // Primeros valores
    (r1024_lib, state1024_lib) := Modelica.Math.Random.Generators.Xorshift1024star.random(state1024_lib);
    (r1024_presto, state1024_presto) := Modelica.Math.Random.Generators.Xorshift1024star.random(state1024_presto);

    // Convertimos el numero uniforme en una distribucion Normal (media 0)
    ruido_libreria := Modelica.Math.Distributions.Normal.quantile(r1024_lib, 0, sigma_lib);
    ruido_presto := Modelica.Math.Distributions.Normal.quantile(r1024_presto, 0, sigma_presto);

  elsewhen sample(0, samplePeriod) then
    // Actualizacion mensual
    (r1024_lib, state1024_lib) := Modelica.Math.Random.Generators.Xorshift1024star.random(pre(state1024_lib));
    (r1024_presto, state1024_presto) := Modelica.Math.Random.Generators.Xorshift1024star.random(pre(state1024_presto));

    ruido_libreria := Modelica.Math.Distributions.Normal.quantile(r1024_lib, 0, sigma_lib);
    ruido_presto := Modelica.Math.Distributions.Normal.quantile(r1024_presto, 0, sigma_presto);
  end when;

equation
  // ==========================================
  // ECUACIONES DEL NEGOCIO
  // ==========================================

  // --- LÓGICA PARA LIBRERÍA ---
  libreria_consumo = max(0, 1000 + ruido_libreria);
  libreria_rvc = max(libreria_rvc_min, min(libreria_rvc_max, 1.0 + (libreria_consumo * 0.005)));
  libreria_precio_venta = libreria_rvc * libreria_costo_base;
  libreria_compra_mensual = min(libreria_consumo, libreria_stock_max);

  // --- LÓGICA PARA PRESTOBARBAS ---
  presto_consumo = max(0, 300 + ruido_presto);
  presto_rvc = max(presto_rvc_min, min(presto_rvc_max, 1.0 + (presto_consumo * 0.008)));
  presto_precio_venta = presto_rvc * presto_costo_base;
  presto_compra_mensual = min(presto_consumo, presto_stock_max);

end SimulacionStockMensual;