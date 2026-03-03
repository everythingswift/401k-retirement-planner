import { useState, useMemo } from "react";
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, AreaChart, Area, ReferenceLine } from "recharts";

const fmt = (n) =>
  n >= 1_000_000
    ? `${(n / 1_000_000).toFixed(2)}M`
    : n >= 1_000
    ? `${(n / 1_000).toFixed(0)}K`
    : `${Math.round(n).toLocaleString()}`;

const fmtFull = (n) => `${Math.round(n).toLocaleString()}`;

function Slider({ label, value, min, max, step, onChange, format, note }) {
  return (
    <div style={{ marginBottom: 18 }}>
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 4 }}>
        <span style={{ fontSize: 12, color: "#94a3b8", letterSpacing: "0.05em", textTransform: "uppercase", fontFamily: "'DM Mono', monospace" }}>{label}</span>
        <span style={{ fontSize: 14, fontWeight: 700, color: "#f0c040", fontFamily: "'DM Mono', monospace" }}>{format ? format(value) : value}</span>
      </div>
      <input
        type="range" min={min} max={max} step={step} value={value}
        onChange={(e) => onChange(Number(e.target.value))}
        style={{ width: "100%", accentColor: "#f0c040", cursor: "pointer" }}
      />
      {note && <div style={{ fontSize: 10, color: "#64748b", marginTop: 2 }}>{note}</div>}
    </div>
  );
}

function StatCard({ label, value, sub, color = "#f0c040", big }) {
  return (
    <div style={{
      background: "rgba(255,255,255,0.03)",
      border: `1px solid rgba(240,192,64,0.15)`,
      borderRadius: 12,
      padding: "16px 20px",
      flex: 1,
      minWidth: 150
    }}>
      <div style={{ fontSize: 11, color: "#64748b", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: 6, fontFamily: "'DM Mono', monospace" }}>{label}</div>
      <div style={{ fontSize: big ? 22 : 18, fontWeight: 800, color, fontFamily: "'DM Mono', monospace", lineHeight: 1.1 }}>{value}</div>
      {sub && <div style={{ fontSize: 11, color: "#64748b", marginTop: 4 }}>{sub}</div>}
    </div>
  );
}

export default function RetirementPlanner() {
  // Core levers
  const [retireAge, setRetireAge] = useState(58);
  const [currentAge, setCurrentAge] = useState(50);
  const [principal, setPrincipal] = useState(4_000_000);
  const [cashReserve, setCashReserve] = useState(500_000);
  const [cashReserveYears, setCashReserveYears] = useState(5);

  // Income
  const [rentalIncome, setRentalIncome] = useState(30_000);
  const [socialSecurityAge, setSocialSecurityAge] = useState(67);
  const [socialSecurityAmt, setSocialSecurityAmt] = useState(28_000); // annual
  const [annualSpend, setAnnualSpend] = useState(130_000);

  // Fixed vs variable costs
  const [fixedCosts, setFixedCosts] = useState(80_000); // incl property tax
  const [propertyTax, setPropertyTax] = useState(14_000);

  // Investments
  const [bondPct, setBondPct] = useState(37.5); // % of investable (after cash reserve)
  const [bondReturn, setBondReturn] = useState(5.0);
  const [equityReturn, setEquityReturn] = useState(8.0);
  const [equityFlatYears, setEquityFlatYears] = useState(1); // flat years per 5yr cycle
  const [inflationRate, setInflationRate] = useState(3.0);

  // Tabs
  const [tab, setTab] = useState("overview");

  const investable = principal - cashReserve;
  const bondAmt = (bondPct / 100) * investable;
  const equityAmt = investable - bondAmt;
  const variableCosts = annualSpend - fixedCosts;
  const yearsToRetire = Math.max(0, retireAge - currentAge);
  const projectionYears = 25; // project 25 years post-retirement

  // Year-by-year projection
  const projection = useMemo(() => {
    let bonds = bondAmt;
    let equity = equityAmt;
    let cash = cashReserve;
    let rows = [];

    for (let yr = 0; yr <= projectionYears; yr++) {
      const calYear = 2025 + yearsToRetire + yr;
      const age = retireAge + yr;
      const inflFactor = Math.pow(1 + inflationRate / 100, yr);
      const spend = annualSpend * inflFactor;
      const rental = rentalIncome * inflFactor;
      const ss = age >= socialSecurityAge ? socialSecurityAmt * inflFactor : 0;
      const totalIncome = rental + ss;
      const gap = spend - totalIncome; // how much to pull from investments

      // Bond returns
      const bondGain = bonds * (bondReturn / 100);
      // Equity returns (flat on equityFlatYears of 5)
      const cyclePos = yr % 5;
      const eqRate = cyclePos < (5 - equityFlatYears) ? equityReturn / 100 : 0;
      const equityGain = equity * eqRate;

      const totalReturn = bondGain + equityGain;
      const totalPortfolio = bonds + equity + cash;

      // Withdraw gap from cash first, then bonds, then equity
      let gapLeft = Math.max(0, gap);
      let cashWithdraw = Math.min(cash, gapLeft);
      cash -= cashWithdraw;
      gapLeft -= cashWithdraw;
      let bondWithdraw = Math.min(bonds, gapLeft);
      bonds -= bondWithdraw;
      gapLeft -= bondWithdraw;
      let equityWithdraw = Math.min(equity, gapLeft);
      equity -= equityWithdraw;

      // Add gains
      bonds += bondGain;
      equity += equityGain;

      // Refill cash if depleted and we have 2+ yrs left of reserve
      if (cash < annualSpend && bonds + equity > 0) {
        const refill = Math.min(annualSpend * 2 - cash, bonds * 0.05);
        bonds -= refill;
        cash += refill;
      }

      rows.push({
        yr,
        age,
        calYear,
        bonds: Math.max(0, bonds),
        equity: Math.max(0, equity),
        cash: Math.max(0, cash),
        total: Math.max(0, bonds + equity + cash),
        totalReturn,
        spend,
        rental,
        ss,
        totalIncome,
        gap: Math.max(0, gap),
        bondGain,
        equityGain,
      });
    }
    return rows;
  }, [
    bondAmt, equityAmt, cashReserve, annualSpend, rentalIncome,
    socialSecurityAge, socialSecurityAmt, inflationRate,
    bondReturn, equityReturn, equityFlatYears, projectionYears,
    retireAge, yearsToRetire
  ]);

  const yr5 = projection[5] || projection[projection.length - 1];
  const yr20 = projection[20] || projection[projection.length - 1];
  const endPortfolio = projection[projection.length - 1]?.total || 0;
  const annualInvestReturn = bondAmt * (bondReturn / 100) + equityAmt * (equityReturn / 100);
  const netCashflow = annualInvestReturn + rentalIncome - annualSpend;

  const tabStyle = (t) => ({
    padding: "8px 18px",
    borderRadius: 8,
    border: "none",
    cursor: "pointer",
    fontSize: 12,
    fontFamily: "'DM Mono', monospace",
    textTransform: "uppercase",
    letterSpacing: "0.08em",
    fontWeight: 600,
    background: tab === t ? "#f0c040" : "rgba(255,255,255,0.05)",
    color: tab === t ? "#0f0f0f" : "#64748b",
    transition: "all 0.2s"
  });

  const CustomTooltip = ({ active, payload, label }) => {
    if (!active || !payload?.length) return null;
    return (
      <div style={{ background: "#1a1f2e", border: "1px solid rgba(240,192,64,0.3)", borderRadius: 8, padding: "10px 14px", fontFamily: "'DM Mono', monospace", fontSize: 11 }}>
        <div style={{ color: "#f0c040", marginBottom: 6 }}>Age {label} · {2025 + yearsToRetire + (label - retireAge)}</div>
        {payload.map((p) => (
          <div key={p.name} style={{ color: p.color, marginBottom: 2 }}>{p.name}: {fmt(p.value)}</div>
        ))}
      </div>
    );
  };

  return (
    <div style={{
      minHeight: "100vh",
      background: "#0a0d14",
      color: "#e2e8f0",
      fontFamily: "'Crimson Pro', Georgia, serif",
      padding: "0 0 60px"
    }}>
      {/* Header */}
      <div style={{ background: "linear-gradient(135deg, #0f1623 0%, #141b2d 100%)", borderBottom: "1px solid rgba(240,192,64,0.15)", padding: "28px 40px" }}>
        <div style={{ maxWidth: 1100, margin: "0 auto" }}>
          <div style={{ display: "flex", alignItems: "baseline", gap: 16, marginBottom: 4 }}>
            <div style={{ fontSize: 11, color: "#f0c040", fontFamily: "'DM Mono', monospace", letterSpacing: "0.2em", textTransform: "uppercase" }}>USA Retirement Planner</div>
            <div style={{ fontSize: 11, color: "#334155", fontFamily: "'DM Mono', monospace" }}>· 4% Rule · Buckets · SS · Inflation</div>
          </div>
          <h1 style={{ fontSize: 32, fontWeight: 400, margin: 0, letterSpacing: "-0.02em", color: "#f8fafc" }}>
            Your Retirement <span style={{ color: "#f0c040", fontStyle: "italic" }}>Command Center</span>
          </h1>
          <p style={{ margin: "8px 0 0", fontSize: 15, color: "#64748b" }}>Tweak every lever · See 25-year projections · All numbers inflation-adjusted</p>
        </div>
      </div>

      <div style={{ maxWidth: 1100, margin: "0 auto", padding: "32px 40px 0" }}>
        {/* Key Stats Row */}
        <div style={{ display: "flex", gap: 12, flexWrap: "wrap", marginBottom: 32 }}>
          <StatCard label="Investable Capital" value={fmt(investable)} sub={`After ${(cashReserve/1000).toFixed(0)}K cash reserve`} big />
          <StatCard label="Yr 1 Gross Return" value={fmt(annualInvestReturn)} sub={`Bonds + Equity gains`} color="#34d399" big />
          <StatCard label="Net Cash Flow Yr 1" value={fmt(netCashflow)} sub={`Return + Rent − Spend`} color={netCashflow >= 0 ? "#34d399" : "#f87171"} big />
          <StatCard label="Portfolio @ 5 Yrs" value={fmt(yr5?.total)} sub={`Age ${yr5?.age}`} big />
          <StatCard label="Portfolio @ 20 Yrs" value={fmt(yr20?.total)} sub={`Age ${yr20?.age} · Inflation adj.`} big />
        </div>

        {/* Main Layout */}
        <div style={{ display: "grid", gridTemplateColumns: "340px 1fr", gap: 24 }}>
          {/* Controls Panel */}
          <div style={{ background: "rgba(255,255,255,0.02)", border: "1px solid rgba(255,255,255,0.06)", borderRadius: 16, padding: 24 }}>
            <div style={{ fontSize: 11, color: "#f0c040", fontFamily: "'DM Mono', monospace", letterSpacing: "0.15em", textTransform: "uppercase", marginBottom: 20, borderBottom: "1px solid rgba(240,192,64,0.15)", paddingBottom: 10 }}>
              ⚙ Your Levers
            </div>

            <div style={{ fontSize: 10, color: "#475569", textTransform: "uppercase", letterSpacing: "0.12em", marginBottom: 12, fontFamily: "'DM Mono', monospace" }}>── Who You Are</div>
            <Slider label="Current Age" value={currentAge} min={35} max={70} step={1} onChange={setCurrentAge} />
            <Slider label="Retirement Age" value={retireAge} min={currentAge + 1} max={80} step={1} onChange={setRetireAge}
              note={`${yearsToRetire} years from now · Year ${2025 + yearsToRetire}`} />
            <Slider label="Total Principal ($)" value={principal} min={500_000} max={10_000_000} step={50_000}
              onChange={setPrincipal} format={fmt} note="Your 4M pool from 401k + investments" />

            <div style={{ fontSize: 10, color: "#475569", textTransform: "uppercase", letterSpacing: "0.12em", margin: "16px 0 12px", fontFamily: "'DM Mono', monospace" }}>── Cash Bucket</div>
            <Slider label="Cash Reserve ($)" value={cashReserve} min={0} max={1_000_000} step={25_000} onChange={setCashReserve} format={fmt}
              note="Your 500K set aside for 5 yrs living" />
            <Slider label="Reserve Covers (yrs)" value={cashReserveYears} min={1} max={10} step={1} onChange={setCashReserveYears} />

            <div style={{ fontSize: 10, color: "#475569", textTransform: "uppercase", letterSpacing: "0.12em", margin: "16px 0 12px", fontFamily: "'DM Mono', monospace" }}>── Annual Income & Spend</div>
            <Slider label="Annual Spending ($)" value={annualSpend} min={50_000} max={400_000} step={5_000} onChange={setAnnualSpend} format={fmt} />
            <Slider label="Fixed Costs ($)" value={fixedCosts} min={20_000} max={300_000} step={5_000} onChange={setFixedCosts} format={fmt}
              note={`Incl. property tax. Variable: ${fmt(Math.max(0, annualSpend - fixedCosts))}`} />
            <Slider label="Rental Income ($)" value={rentalIncome} min={0} max={120_000} step={2_500} onChange={setRentalIncome} format={fmt} note="From 2 properties" />
            <Slider label="Social Security Age" value={socialSecurityAge} min={62} max={70} step={1} onChange={setSocialSecurityAge}
              note="62 = reduced · 67 = full · 70 = max" />
            <Slider label="SS Annual Benefit ($)" value={socialSecurityAmt} min={0} max={60_000} step={1_000} onChange={setSocialSecurityAmt} format={fmt}
              note="Check ssa.gov for your estimate" />

            <div style={{ fontSize: 10, color: "#475569", textTransform: "uppercase", letterSpacing: "0.12em", margin: "16px 0 12px", fontFamily: "'DM Mono', monospace" }}>── Investment Returns</div>
            <Slider label="Bond Allocation %" value={bondPct} min={0} max={100} step={2.5} onChange={setBondPct}
              format={(v) => `${v.toFixed(1)}% · ${fmt(bondAmt)} bonds / ${fmt(equityAmt)} equity`} />
            <Slider label="Bond Return %" value={bondReturn} min={1} max={8} step={0.25} onChange={setBondReturn}
              format={(v) => `${v.toFixed(2)}%`} note="5% realistic for 2024-era Treasuries/corporates" />
            <Slider label="Equity Return %" value={equityReturn} min={2} max={15} step={0.5} onChange={setEquityReturn}
              format={(v) => `${v.toFixed(1)}%`} note="S&P 500 ~10% nominal, 7% real historically" />
            <Slider label="Flat/Down Years (per 5)" value={equityFlatYears} min={0} max={3} step={1} onChange={setEquityFlatYears}
              note="Your scenario: 1 flat year in yr 5 cycle" />
            <Slider label="Inflation Rate %" value={inflationRate} min={1} max={7} step={0.25} onChange={setInflationRate}
              format={(v) => `${v.toFixed(2)}%`} note="All spending grows at this rate" />
          </div>

          {/* Charts & Tables */}
          <div>
            {/* Tabs */}
            <div style={{ display: "flex", gap: 8, marginBottom: 20 }}>
              {["overview", "income", "table"].map((t) => (
                <button key={t} style={tabStyle(t)} onClick={() => setTab(t)}>
                  {t === "overview" ? "📈 Portfolio Growth" : t === "income" ? "💵 Income vs Spend" : "📋 Year-by-Year"}
                </button>
              ))}
            </div>

            {tab === "overview" && (
              <div style={{ background: "rgba(255,255,255,0.02)", border: "1px solid rgba(255,255,255,0.06)", borderRadius: 16, padding: 24 }}>
                <div style={{ fontSize: 13, color: "#94a3b8", marginBottom: 16 }}>Portfolio Buckets Over Time (25 years post-retirement)</div>
                <ResponsiveContainer width="100%" height={320}>
                  <AreaChart data={projection} margin={{ top: 10, right: 10, left: 10, bottom: 0 }}>
                    <defs>
                      <linearGradient id="gBond" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#60a5fa" stopOpacity={0.4} />
                        <stop offset="95%" stopColor="#60a5fa" stopOpacity={0.05} />
                      </linearGradient>
                      <linearGradient id="gEq" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#34d399" stopOpacity={0.4} />
                        <stop offset="95%" stopColor="#34d399" stopOpacity={0.05} />
                      </linearGradient>
                      <linearGradient id="gCash" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#f0c040" stopOpacity={0.3} />
                        <stop offset="95%" stopColor="#f0c040" stopOpacity={0.05} />
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.04)" />
                    <XAxis dataKey="age" stroke="#334155" tick={{ fill: "#475569", fontSize: 11, fontFamily: "DM Mono" }} label={{ value: "Age", position: "insideBottom", offset: -2, fill: "#475569", fontSize: 11 }} />
                    <YAxis stroke="#334155" tick={{ fill: "#475569", fontSize: 11, fontFamily: "DM Mono" }} tickFormatter={(v) => fmt(v)} />
                    <Tooltip content={<CustomTooltip />} />
                    <Legend wrapperStyle={{ fontSize: 11, fontFamily: "DM Mono", color: "#94a3b8" }} />
                    <Area type="monotone" dataKey="equity" name="Equity" stackId="1" stroke="#34d399" fill="url(#gEq)" strokeWidth={2} />
                    <Area type="monotone" dataKey="bonds" name="Bonds" stackId="1" stroke="#60a5fa" fill="url(#gBond)" strokeWidth={2} />
                    <Area type="monotone" dataKey="cash" name="Cash" stackId="1" stroke="#f0c040" fill="url(#gCash)" strokeWidth={2} />
                  </AreaChart>
                </ResponsiveContainer>

                {/* Scenario summary boxes */}
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 12, marginTop: 20 }}>
                  {[5, 10, 20].map((y) => {
                    const d = projection[y];
                    if (!d) return null;
                    const grew = d.total > principal;
                    return (
                      <div key={y} style={{ background: "rgba(255,255,255,0.03)", borderRadius: 10, padding: "14px 16px", border: `1px solid ${grew ? "rgba(52,211,153,0.2)" : "rgba(248,113,113,0.2)"}` }}>
                        <div style={{ fontSize: 10, color: "#64748b", textTransform: "uppercase", letterSpacing: "0.1em", fontFamily: "DM Mono", marginBottom: 4 }}>Year +{y} · Age {d.age}</div>
                        <div style={{ fontSize: 18, fontWeight: 800, color: grew ? "#34d399" : "#f87171", fontFamily: "DM Mono" }}>{fmt(d.total)}</div>
                        <div style={{ fontSize: 10, color: "#475569", marginTop: 4 }}>{grew ? "▲" : "▼"} {fmt(Math.abs(d.total - principal))} vs start</div>
                        <div style={{ fontSize: 10, color: "#64748b" }}>Return that yr: {fmt(d.totalReturn)}</div>
                      </div>
                    );
                  })}
                </div>

                {/* 4% Rule context */}
                <div style={{ marginTop: 20, padding: "14px 18px", background: "rgba(240,192,64,0.06)", border: "1px solid rgba(240,192,64,0.2)", borderRadius: 10 }}>
                  <div style={{ fontSize: 11, color: "#f0c040", fontFamily: "DM Mono", marginBottom: 6 }}>💡 USA Context: The 4% Rule</div>
                  <div style={{ fontSize: 13, color: "#94a3b8", lineHeight: 1.7 }}>
                    The classic "Trinity Study" says withdraw 4% of your portfolio annually — your {fmt(principal)} supports <strong style={{ color: "#e2e8f0" }}>{fmt(principal * 0.04)}/yr</strong> safely for 30 years.
                    Your spend of {fmt(annualSpend)} is a <strong style={{ color: annualSpend <= principal * 0.04 ? "#34d399" : "#f87171" }}>{((annualSpend / principal) * 100).toFixed(1)}% withdrawal rate</strong> — {annualSpend <= principal * 0.04 ? "✅ within safe zone" : "⚠ above 4% — offset with rental + SS"}.
                    With rent + SS, effective withdrawal drops to <strong style={{ color: "#34d399" }}>{fmt(Math.max(0, annualSpend - rentalIncome - (retireAge >= socialSecurityAge ? socialSecurityAmt : 0)))}/yr</strong> from portfolio.
                  </div>
                </div>
              </div>
            )}

            {tab === "income" && (
              <div style={{ background: "rgba(255,255,255,0.02)", border: "1px solid rgba(255,255,255,0.06)", borderRadius: 16, padding: 24 }}>
                <div style={{ fontSize: 13, color: "#94a3b8", marginBottom: 16 }}>Income Sources vs. Spending (inflation-adjusted)</div>
                <ResponsiveContainer width="100%" height={300}>
                  <LineChart data={projection} margin={{ top: 10, right: 10, left: 10, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.04)" />
                    <XAxis dataKey="age" stroke="#334155" tick={{ fill: "#475569", fontSize: 11, fontFamily: "DM Mono" }} />
                    <YAxis stroke="#334155" tick={{ fill: "#475569", fontSize: 11, fontFamily: "DM Mono" }} tickFormatter={(v) => fmt(v)} />
                    <Tooltip content={<CustomTooltip />} />
                    <Legend wrapperStyle={{ fontSize: 11, fontFamily: "DM Mono" }} />
                    <Line type="monotone" dataKey="spend" name="Total Spending" stroke="#f87171" strokeWidth={2} dot={false} />
                    <Line type="monotone" dataKey="totalReturn" name="Investment Return" stroke="#34d399" strokeWidth={2} dot={false} />
                    <Line type="monotone" dataKey="rental" name="Rental Income" stroke="#f0c040" strokeWidth={1.5} strokeDasharray="5 3" dot={false} />
                    <Line type="monotone" dataKey="ss" name="Social Security" stroke="#a78bfa" strokeWidth={1.5} strokeDasharray="5 3" dot={false} />
                    <ReferenceLine x={socialSecurityAge} stroke="#a78bfa" strokeDasharray="4 4" label={{ value: `SS @ ${socialSecurityAge}`, fill: "#a78bfa", fontSize: 10, fontFamily: "DM Mono" }} />
                  </LineChart>
                </ResponsiveContainer>

                <div style={{ marginTop: 20, display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
                  <div style={{ background: "rgba(255,255,255,0.03)", borderRadius: 10, padding: "14px 16px" }}>
                    <div style={{ fontSize: 11, color: "#64748b", fontFamily: "DM Mono", marginBottom: 8, textTransform: "uppercase" }}>Year 1 Income Breakdown</div>
                    {[
                      ["Bond Gains", fmt(bondAmt * bondReturn / 100), "#60a5fa"],
                      ["Equity Gains", fmt(equityAmt * equityReturn / 100), "#34d399"],
                      ["Rental Income", fmt(rentalIncome), "#f0c040"],
                      ["Social Security", retireAge >= socialSecurityAge ? fmt(socialSecurityAmt) : "Not yet", "#a78bfa"],
                    ].map(([l, v, c]) => (
                      <div key={l} style={{ display: "flex", justifyContent: "space-between", marginBottom: 6, fontSize: 13 }}>
                        <span style={{ color: "#94a3b8" }}>{l}</span>
                        <span style={{ color: c, fontFamily: "DM Mono", fontWeight: 700 }}>{v}</span>
                      </div>
                    ))}
                    <div style={{ borderTop: "1px solid rgba(255,255,255,0.08)", paddingTop: 8, marginTop: 4, display: "flex", justifyContent: "space-between", fontSize: 14 }}>
                      <span style={{ color: "#e2e8f0" }}>vs. Spending</span>
                      <span style={{ color: "#f87171", fontFamily: "DM Mono", fontWeight: 800 }}>{fmt(annualSpend)}</span>
                    </div>
                  </div>
                  <div style={{ background: "rgba(255,255,255,0.03)", borderRadius: 10, padding: "14px 16px" }}>
                    <div style={{ fontSize: 11, color: "#64748b", fontFamily: "DM Mono", marginBottom: 8, textTransform: "uppercase" }}>Cost Structure</div>
                    {[
                      ["Fixed Costs", fmt(fixedCosts), "#94a3b8"],
                      ["Property Tax (incl.)", fmt(propertyTax), "#64748b"],
                      ["Variable / Lifestyle", fmt(Math.max(0, annualSpend - fixedCosts)), "#f0c040"],
                    ].map(([l, v, c]) => (
                      <div key={l} style={{ display: "flex", justifyContent: "space-between", marginBottom: 6, fontSize: 13 }}>
                        <span style={{ color: "#94a3b8" }}>{l}</span>
                        <span style={{ color: c, fontFamily: "DM Mono", fontWeight: 700 }}>{v}</span>
                      </div>
                    ))}
                    <div style={{ marginTop: 12, fontSize: 11, color: "#475569" }}>
                      Fixed = {((fixedCosts / annualSpend) * 100).toFixed(0)}% of spend · Flex = {(((annualSpend - fixedCosts) / annualSpend) * 100).toFixed(0)}%
                    </div>
                  </div>
                </div>
              </div>
            )}

            {tab === "table" && (
              <div style={{ background: "rgba(255,255,255,0.02)", border: "1px solid rgba(255,255,255,0.06)", borderRadius: 16, padding: 24 }}>
                <div style={{ fontSize: 13, color: "#94a3b8", marginBottom: 16 }}>Year-by-Year Projection (all $ inflation-adjusted)</div>
                <div style={{ overflowX: "auto" }}>
                  <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 12, fontFamily: "DM Mono" }}>
                    <thead>
                      <tr style={{ borderBottom: "1px solid rgba(240,192,64,0.3)" }}>
                        {["Yr", "Age", "CalYr", "Bonds", "Equity", "Cash", "Total", "Return", "Spend", "SS"].map((h) => (
                          <th key={h} style={{ padding: "8px 10px", color: "#f0c040", textAlign: "right", fontWeight: 600, fontSize: 10, letterSpacing: "0.05em" }}>{h}</th>
                        ))}
                      </tr>
                    </thead>
                    <tbody>
                      {projection.map((r, i) => {
                        const isGood = r.total >= principal;
                        const highlight = i % 5 === 0;
                        return (
                          <tr key={r.yr} style={{ borderBottom: "1px solid rgba(255,255,255,0.04)", background: highlight ? "rgba(240,192,64,0.04)" : "transparent" }}>
                            <td style={{ padding: "7px 10px", color: "#64748b", textAlign: "right" }}>{r.yr}</td>
                            <td style={{ padding: "7px 10px", color: "#e2e8f0", textAlign: "right", fontWeight: 700 }}>{r.age}</td>
                            <td style={{ padding: "7px 10px", color: "#64748b", textAlign: "right" }}>{r.calYear}</td>
                            <td style={{ padding: "7px 10px", color: "#60a5fa", textAlign: "right" }}>{fmt(r.bonds)}</td>
                            <td style={{ padding: "7px 10px", color: "#34d399", textAlign: "right" }}>{fmt(r.equity)}</td>
                            <td style={{ padding: "7px 10px", color: "#f0c040", textAlign: "right" }}>{fmt(r.cash)}</td>
                            <td style={{ padding: "7px 10px", color: isGood ? "#34d399" : "#f87171", textAlign: "right", fontWeight: 700 }}>{fmt(r.total)}</td>
                            <td style={{ padding: "7px 10px", color: "#94a3b8", textAlign: "right" }}>{fmt(r.totalReturn)}</td>
                            <td style={{ padding: "7px 10px", color: "#f87171", textAlign: "right" }}>{fmt(r.spend)}</td>
                            <td style={{ padding: "7px 10px", color: "#a78bfa", textAlign: "right" }}>{r.ss > 0 ? fmt(r.ss) : "–"}</td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {/* Bottom insights */}
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, marginTop: 16 }}>
              <div style={{ background: "rgba(255,255,255,0.02)", border: "1px solid rgba(255,255,255,0.06)", borderRadius: 12, padding: 18 }}>
                <div style={{ fontSize: 11, color: "#f0c040", fontFamily: "DM Mono", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: 10 }}>🇺🇸 USA Investment Vehicles</div>
                <div style={{ fontSize: 12, color: "#94a3b8", lineHeight: 1.8 }}>
                  <strong style={{ color: "#e2e8f0" }}>Bonds (your 5% goal):</strong> 2025 10-yr Treasury ~4.3%, I-bonds 5.27%, TIPS, Investment-grade corps.<br />
                  <strong style={{ color: "#e2e8f0" }}>Equity 8%:</strong> VTSAX / VOO (total market index), dividend ETFs (VYM, SCHD), target-date funds.<br />
                  <strong style={{ color: "#e2e8f0" }}>Tax-efficient:</strong> Municipal bonds (tax-free), Roth conversions post-retire, qualified dividends taxed at 0-15%.<br />
                  <strong style={{ color: "#e2e8f0" }}>SS strategy:</strong> Delay to 70 = 24% more than age 67 payout.
                </div>
              </div>
              <div style={{ background: "rgba(255,255,255,0.02)", border: "1px solid rgba(255,255,255,0.06)", borderRadius: 12, padding: 18 }}>
                <div style={{ fontSize: 11, color: "#f0c040", fontFamily: "DM Mono", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: 10 }}>📐 Your Scenario at a Glance</div>
                <div style={{ fontSize: 12, color: "#94a3b8", lineHeight: 1.9 }}>
                  <span style={{ color: "#60a5fa", fontFamily: "DM Mono" }}>{fmt(bondAmt)}</span> in bonds · <span style={{ color: "#34d399", fontFamily: "DM Mono" }}>{fmt(equityAmt)}</span> in equity<br />
                  Rental covers <strong style={{ color: "#e2e8f0" }}>{((rentalIncome / annualSpend) * 100).toFixed(0)}%</strong> of spend · SS kicks in at <strong style={{ color: "#e2e8f0" }}>age {socialSecurityAge}</strong><br />
                  Cash runway: <strong style={{ color: "#e2e8f0" }}>{cashReserveYears} yrs</strong> without touching investments<br />
                  Portfolio at 25 yrs: <strong style={{ color: endPortfolio > principal ? "#34d399" : "#f87171", fontFamily: "DM Mono" }}>{fmt(endPortfolio)}</strong>
                  {endPortfolio > principal ? " ✅ Growing!" : " ⚠ Declining"}<br />
                  <span style={{ color: "#64748b", fontSize: 11 }}>Years to retirement: {yearsToRetire} · Start year: {2025 + yearsToRetire}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Crimson+Pro:ital,wght@0,400;0,700;1,400&family=DM+Mono:wght@400;500;600&display=swap');
        input[type=range] { height: 4px; }
        * { box-sizing: border-box; }
      `}</style>
    </div>
  );
}
