import { useState, useMemo } from "react";
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend,
  ResponsiveContainer, AreaChart, Area, ReferenceLine,
} from "recharts";

interface CustomTooltipProps {
  active?: boolean;
  payload?: Array<{ name: string; value: number; color: string }>;
  label?: number;
}

const fmt = (n: number) =>
  n >= 1_000_000
    ? `${(n / 1_000_000).toFixed(2)}M`
    : n >= 1_000
    ? `${(n / 1_000).toFixed(0)}K`
    : `${Math.round(n).toLocaleString()}`;

interface SliderProps {
  label: string;
  value: number;
  min: number;
  max: number;
  step: number;
  onChange: (v: number) => void;
  format?: (v: number) => string;
  note?: string;
}

function Slider({ label, value, min, max, step, onChange, format, note }: SliderProps) {
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

interface StatCardProps {
  label: string;
  value: string;
  sub?: string;
  color?: string;
  big?: boolean;
}

function StatCard({ label, value, sub, color = "#f0c040", big }: StatCardProps) {
  return (
    <div style={{
      background: "rgba(255,255,255,0.03)",
      border: `1px solid rgba(240,192,64,0.15)`,
      borderRadius: 12,
      padding: "16px 20px",
      flex: 1,
      minWidth: 150,
    }}>
      <div style={{ fontSize: 11, color: "#64748b", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: 6, fontFamily: "'DM Mono', monospace" }}>{label}</div>
      <div style={{ fontSize: big ? 22 : 18, fontWeight: 800, color, fontFamily: "'DM Mono', monospace", lineHeight: 1.1 }}>{value}</div>
      {sub && <div style={{ fontSize: 11, color: "#64748b", marginTop: 4 }}>{sub}</div>}
    </div>
  );
}

interface ProjectionRow {
  yr: number;
  age: number;
  bonds: number;
  equity: number;
  cash: number;
  total: number;
  totalReturn: number;
  spend: number;
  rental: number;
  ss: number;
  totalIncome: number;
  gap: number;
  bondGain: number;
  equityGain: number;
}

const DISCLAIMERS: [string, string, string][] = [
  ["⚠️", "Not financial advice", "This tool is for informational and educational purposes only. Always consult a licensed financial advisor before making retirement decisions."],
  ["📊", "Returns are not guaranteed", "Bond and equity returns are variable. Historical performance does not guarantee future results. Market downturns can significantly impact projections."],
  ["🏥", "Unexpected expenses excluded", "Healthcare costs, emergencies, home repairs, and other one-time large costs are not modeled. Maintain a separate buffer for these."],
  ["🧾", "Taxes not included", "Capital gains, income tax, Required Minimum Distributions (RMDs), and state taxes are not factored in. Your real take-home will differ."],
  ["🔮", "Projections are estimates", "Outputs are based on your inputs and simplified assumptions. Real-world outcomes will vary — sometimes significantly."],
];

function DisclaimerModal({ onAccept }: { onAccept: () => void }) {
  return (
    <div style={{
      position: "fixed", inset: 0, background: "rgba(0,0,0,0.88)", zIndex: 1000,
      display: "flex", alignItems: "center", justifyContent: "center", padding: 20,
    }}>
      <div style={{
        background: "#0f1623", border: "1px solid rgba(240,192,64,0.3)", borderRadius: 20,
        padding: "40px 48px", maxWidth: 660, width: "100%", maxHeight: "90vh", overflowY: "auto",
      }}>
        <div style={{ fontSize: 11, color: "#f0c040", fontFamily: "'DM Mono', monospace", letterSpacing: "0.2em", textTransform: "uppercase", marginBottom: 12 }}>
          Before You Begin
        </div>
        <h2 style={{ fontSize: 26, fontWeight: 400, color: "#f8fafc", margin: "0 0 8px", letterSpacing: "-0.02em" }}>
          The <span style={{ color: "#f0c040", fontStyle: "italic" }}>5-Year Bucket</span> Strategy
        </h2>
        <p style={{ fontSize: 14, color: "#94a3b8", lineHeight: 1.75, margin: "0 0 24px" }}>
          Rather than withdrawing a fixed 4% every year into a low-earning account, this planner keeps your wealth <strong style={{ color: "#e2e8f0" }}>actively growing</strong> in bonds and equity throughout retirement.
          You start with 5 years of net living expenses in cash. The rest compounds in your investment pot. Every 5 years, you refill the cash bucket by withdrawing from bonds and equity — so your pot never sits idle.
        </p>

        <div style={{ display: "grid", gap: 4, marginBottom: 24, padding: "16px 20px", background: "rgba(240,192,64,0.06)", borderRadius: 12, border: "1px solid rgba(240,192,64,0.15)" }}>
          {[
            ["Year 0", "Set aside 5 years of net expenses as cash. Rest goes to bonds + equity.", "#f0c040"],
            ["Years 1–5", "Spend from cash. Your investment pot grows untouched.", "#94a3b8"],
            ["End of Year 5", "Withdraw next 5 years of expenses from bonds + equity into cash.", "#34d399"],
            ["Repeat", "Refill every 5 years. Your pot keeps compounding between withdrawals.", "#60a5fa"],
          ].map(([label, desc, color]) => (
            <div key={label} style={{ display: "flex", gap: 14, padding: "6px 0" }}>
              <span style={{ color, fontFamily: "'DM Mono', monospace", fontSize: 11, fontWeight: 700, flexShrink: 0, minWidth: 80 }}>{label}</span>
              <span style={{ color: "#64748b", fontSize: 12, lineHeight: 1.5 }}>{desc}</span>
            </div>
          ))}
        </div>

        <div style={{ borderTop: "1px solid rgba(255,255,255,0.08)", paddingTop: 20, marginBottom: 28 }}>
          <div style={{ fontSize: 11, color: "#f87171", fontFamily: "'DM Mono', monospace", letterSpacing: "0.1em", textTransform: "uppercase", marginBottom: 16 }}>
            Important Disclaimers
          </div>
          {DISCLAIMERS.map(([icon, title, desc]) => (
            <div key={title} style={{ display: "flex", gap: 14, marginBottom: 16 }}>
              <span style={{ fontSize: 20, flexShrink: 0, lineHeight: 1 }}>{icon}</span>
              <div>
                <div style={{ fontSize: 13, fontWeight: 700, color: "#e2e8f0", marginBottom: 3, fontFamily: "'DM Mono', monospace" }}>{title}</div>
                <div style={{ fontSize: 12, color: "#64748b", lineHeight: 1.6 }}>{desc}</div>
              </div>
            </div>
          ))}
        </div>

        <button
          onClick={onAccept}
          style={{
            width: "100%", padding: "14px 24px", background: "#f0c040", border: "none",
            borderRadius: 10, fontSize: 14, fontWeight: 700, cursor: "pointer",
            fontFamily: "'DM Mono', monospace", letterSpacing: "0.1em", textTransform: "uppercase",
            color: "#0f0f0f",
          }}
        >
          I Understand — Start Planning
        </button>
      </div>
    </div>
  );
}

export default function RetirementPlanner() {
  const [disclaimerAccepted, setDisclaimerAccepted] = useState(false);

  // Section 1: Your Retirement
  const [retireAge, setRetireAge] = useState(65);
  const [totalPortfolio, setTotalPortfolio] = useState(500_000);

  // Section 2: Living Expenses
  const [annualSpend, setAnnualSpend] = useState(65_000);

  // Section 3: Additional Income
  const [rentalIncome, setRentalIncome] = useState(0);
  const [socialSecurityAge, setSocialSecurityAge] = useState(67);
  const [socialSecurityAmt, setSocialSecurityAmt] = useState(22_000);

  // Section 4: Investment Assumptions
  const [bondPct, setBondPct] = useState(40);
  const [bondReturn, setBondReturn] = useState(4.5);
  const [equityReturn, setEquityReturn] = useState(7.0);
  const [inflationRate, setInflationRate] = useState(3.0);

  const [tab, setTab] = useState("overview");
  const projectionYears = Math.max(1, 100 - retireAge);

  // Compute the initial 5-year cash reserve (net of rental + SS, inflation-adjusted)
  const initialCash = useMemo(() => {
    const infR = inflationRate / 100;
    let total = 0;
    for (let i = 0; i < 5; i++) {
      const inflFactor = Math.pow(1 + infR, i);
      const age = retireAge + i;
      const ss = age >= socialSecurityAge ? socialSecurityAmt * inflFactor : 0;
      const rental = rentalIncome * inflFactor;
      total += Math.max(0, annualSpend * inflFactor - rental - ss);
    }
    return total;
  }, [inflationRate, retireAge, socialSecurityAge, socialSecurityAmt, annualSpend, rentalIncome]);

  const investable = Math.max(0, totalPortfolio - initialCash);
  const bondAmt = (bondPct / 100) * investable;
  const equityAmt = investable - bondAmt;

  const projection = useMemo<ProjectionRow[]>(() => {
    const infR = inflationRate / 100;
    const bondR = bondReturn / 100;
    const eqR = equityReturn / 100;

    // Build initial 5-year cash reserve (same logic as initialCash above)
    let cash = 0;
    for (let i = 0; i < 5; i++) {
      const inflFactor = Math.pow(1 + infR, i);
      const age = retireAge + i;
      const ss = age >= socialSecurityAge ? socialSecurityAmt * inflFactor : 0;
      const rental = rentalIncome * inflFactor;
      cash += Math.max(0, annualSpend * inflFactor - rental - ss);
    }

    const inv = Math.max(0, totalPortfolio - cash);
    let bonds = inv * (bondPct / 100);
    let equity = inv * (1 - bondPct / 100);
    const rows: ProjectionRow[] = [];

    for (let yr = 0; yr < projectionYears; yr++) {
      const inflFactor = Math.pow(1 + infR, yr);
      const age = retireAge + yr;
      const spend = annualSpend * inflFactor;
      const rental = rentalIncome * inflFactor;
      const ss = age >= socialSecurityAge ? socialSecurityAmt * inflFactor : 0;
      const netWithdrawal = Math.max(0, spend - rental - ss);

      // Apply investment returns
      const eqRate = eqR;
      const bondGain = bonds * bondR;
      const equityGain = equity * eqRate;
      bonds += bondGain;
      equity += equityGain;

      // Withdraw net spending from cash
      cash = Math.max(0, cash - netWithdrawal);

      // Every 5 years, refill cash bucket from bonds + equity for next 5 years
      if ((yr + 1) % 5 === 0 && yr < projectionYears - 1) {
        let nextCashNeeded = 0;
        for (let j = 1; j <= 5; j++) {
          const futureInflFactor = Math.pow(1 + infR, yr + j);
          const futureAge = retireAge + yr + j;
          const futureSS = futureAge >= socialSecurityAge ? socialSecurityAmt * futureInflFactor : 0;
          const futureRental = rentalIncome * futureInflFactor;
          nextCashNeeded += Math.max(0, annualSpend * futureInflFactor - futureRental - futureSS);
        }

        const totalInvest = bonds + equity;
        if (totalInvest > 0 && nextCashNeeded > 0) {
          const withdraw = Math.min(nextCashNeeded, totalInvest);
          const bondShare = bonds / totalInvest;
          bonds = Math.max(0, bonds - withdraw * bondShare);
          equity = Math.max(0, equity - withdraw * (1 - bondShare));
          cash += withdraw;
        }
      }

      rows.push({
        yr,
        age,
        bonds: Math.max(0, bonds),
        equity: Math.max(0, equity),
        cash: Math.max(0, cash),
        total: Math.max(0, bonds + equity + cash),
        totalReturn: bondGain + equityGain,
        spend,
        rental,
        ss,
        totalIncome: rental + ss,
        gap: Math.max(0, spend - rental - ss),
        bondGain,
        equityGain,
      });
    }

    return rows;
  }, [
    totalPortfolio, bondPct, bondReturn, equityReturn,
    inflationRate, annualSpend, rentalIncome, socialSecurityAge, socialSecurityAmt,
    retireAge, projectionYears,
  ]);

  const yr5 = projection[5] ?? projection[projection.length - 1];
  const yr20 = projection[20] ?? projection[projection.length - 1];
  const endPortfolio = projection[projection.length - 1]?.total ?? 0;
  const yr1Return = projection[0]?.totalReturn ?? 0;

  const tabStyle = (t: string) => ({
    padding: "8px 18px",
    borderRadius: 8,
    border: "none",
    cursor: "pointer",
    fontSize: 12,
    fontFamily: "'DM Mono', monospace",
    textTransform: "uppercase" as const,
    letterSpacing: "0.08em",
    fontWeight: 600,
    background: tab === t ? "#f0c040" : "rgba(255,255,255,0.05)",
    color: tab === t ? "#0f0f0f" : "#64748b",
    transition: "all 0.2s",
  });

  const CustomTooltip = ({ active, payload, label }: CustomTooltipProps) => {
    if (!active || !payload?.length) return null;
    return (
      <div style={{ background: "#1a1f2e", border: "1px solid rgba(240,192,64,0.3)", borderRadius: 8, padding: "10px 14px", fontFamily: "'DM Mono', monospace", fontSize: 11 }}>
        <div style={{ color: "#f0c040", marginBottom: 6 }}>Age {label}</div>
        {payload.map((p: { name: string; value: number; color: string }) => (
          <div key={p.name} style={{ color: p.color, marginBottom: 2 }}>{p.name}: {fmt(p.value)}</div>
        ))}
      </div>
    );
  };

  return (
    <div style={{ minHeight: "100vh", background: "#0a0d14", color: "#e2e8f0", fontFamily: "'Crimson Pro', Georgia, serif", padding: "0 0 60px" }}>
      {!disclaimerAccepted && <DisclaimerModal onAccept={() => setDisclaimerAccepted(true)} />}

      {/* Header */}
      <div style={{ background: "linear-gradient(135deg, #0f1623 0%, #141b2d 100%)", borderBottom: "1px solid rgba(240,192,64,0.15)", padding: "28px 40px" }}>
        <div style={{ maxWidth: 1100, margin: "0 auto" }}>
          <div style={{ display: "flex", alignItems: "baseline", gap: 16, marginBottom: 4 }}>
            <div style={{ fontSize: 11, color: "#f0c040", fontFamily: "'DM Mono', monospace", letterSpacing: "0.2em", textTransform: "uppercase" }}>Retirement Planner</div>
            <div style={{ fontSize: 11, color: "#334155", fontFamily: "'DM Mono', monospace" }}>· 5-Year Bucket Strategy · Bonds & Equity · SS · Inflation · For Reference Only</div>
          </div>
          <h1 style={{ fontSize: 32, fontWeight: 400, margin: 0, letterSpacing: "-0.02em", color: "#f8fafc" }}>
            Your Retirement <span style={{ color: "#f0c040", fontStyle: "italic" }}>Command Center</span>
          </h1>
          <p style={{ margin: "8px 0 0", fontSize: 15, color: "#64748b" }}>Keep your pot growing · Refill cash every 5 years · All numbers inflation-adjusted · Not financial advice</p>
        </div>
      </div>

      <div style={{ maxWidth: 1100, margin: "0 auto", padding: "32px 40px 0" }}>
        {/* Key Stats Row */}
        <div style={{ display: "flex", gap: 12, flexWrap: "wrap", marginBottom: 32 }}>
          <StatCard label="5-Yr Cash Reserve" value={fmt(initialCash)} sub="Net expenses set aside at retirement" big />
          <StatCard label="Investment Pot" value={fmt(investable)} sub={`${fmt(bondAmt)} bonds · ${fmt(equityAmt)} equity`} color="#34d399" big />
          <StatCard label="Yr 1 Investment Growth" value={fmt(yr1Return)} sub="Bonds + equity returns" color="#34d399" big />
          <StatCard label="Portfolio @ Yr 5" value={fmt(yr5?.total ?? 0)} sub={`Age ${yr5?.age ?? ""} · after first refill`} big />
          <StatCard label="Portfolio @ Yr 20" value={fmt(yr20?.total ?? 0)} sub={`Age ${yr20?.age ?? ""}`} big />
        </div>

        {/* Main Layout */}
        <div style={{ display: "grid", gridTemplateColumns: "340px 1fr", gap: 24 }}>
          {/* Controls Panel */}
          <div style={{ background: "rgba(255,255,255,0.02)", border: "1px solid rgba(255,255,255,0.06)", borderRadius: 16, padding: 24 }}>
            <div style={{ fontSize: 11, color: "#f0c040", fontFamily: "'DM Mono', monospace", letterSpacing: "0.15em", textTransform: "uppercase", marginBottom: 20, borderBottom: "1px solid rgba(240,192,64,0.15)", paddingBottom: 10 }}>
              Your Levers
            </div>

            {/* Section 1 */}
            <div style={{ fontSize: 10, color: "#475569", textTransform: "uppercase", letterSpacing: "0.12em", marginBottom: 12, fontFamily: "'DM Mono', monospace" }}>── 1. Your Retirement</div>
            <Slider label="Retirement Age" value={retireAge} min={45} max={80} step={1}
              onChange={setRetireAge} note="Age at which you stop working" />
            <Slider label="Portfolio Value at Retirement ($)" value={totalPortfolio} min={500_000} max={10_000_000} step={50_000}
              onChange={setTotalPortfolio} format={fmt} note="Total 401k, IRA, savings + investments at retirement" />

            {/* Section 2 */}
            <div style={{ fontSize: 10, color: "#475569", textTransform: "uppercase", letterSpacing: "0.12em", margin: "16px 0 12px", fontFamily: "'DM Mono', monospace" }}>── 2. Living Expenses</div>
            <Slider label="Annual Spending ($)" value={annualSpend} min={30_000} max={400_000} step={5_000}
              onChange={setAnnualSpend} format={fmt} note="Total comfortable lifestyle cost per year (today's dollars)" />

            {/* Section 3 */}
            <div style={{ fontSize: 10, color: "#475569", textTransform: "uppercase", letterSpacing: "0.12em", margin: "16px 0 12px", fontFamily: "'DM Mono', monospace" }}>── 3. Additional Income</div>
            <Slider label="Rental Income ($/yr)" value={rentalIncome} min={0} max={120_000} step={2_500}
              onChange={setRentalIncome} format={fmt} note="Annual income from rental properties" />
            <Slider label="Social Security Starts (Age)" value={socialSecurityAge} min={62} max={70} step={1}
              onChange={setSocialSecurityAge} note="62 = reduced · 67 = full · 70 = max benefit" />
            <Slider label="SS Annual Benefit ($)" value={socialSecurityAmt} min={0} max={60_000} step={1_000}
              onChange={setSocialSecurityAmt} format={fmt} note="Check ssa.gov for your personal estimate" />

            {/* Section 4 */}
            <div style={{ fontSize: 10, color: "#475569", textTransform: "uppercase", letterSpacing: "0.12em", margin: "16px 0 12px", fontFamily: "'DM Mono', monospace" }}>── 4. Investment Assumptions</div>
            <Slider label="Bond vs Equity Allocation" value={bondPct} min={0} max={100} step={2.5}
              onChange={setBondPct}
              format={(v) => `${v.toFixed(1)}% bonds · ${(100 - v).toFixed(1)}% equity`} />
            <Slider label="Bond Return %" value={bondReturn} min={1} max={8} step={0.25}
              onChange={setBondReturn} format={(v) => `${v.toFixed(2)}%`}
              note="5% realistic for Treasuries / investment-grade corps" />
            <Slider label="Equity Return %" value={equityReturn} min={2} max={15} step={0.5}
              onChange={setEquityReturn} format={(v) => `${v.toFixed(1)}%`}
              note="S&P 500 ~10% nominal, ~7% real historically" />
            <Slider label="Inflation Rate %" value={inflationRate} min={1} max={7} step={0.25}
              onChange={setInflationRate} format={(v) => `${v.toFixed(2)}%`}
              note="All spending grows at this rate annually" />
          </div>

          {/* Charts & Tables */}
          <div>
            <div style={{ display: "flex", gap: 8, marginBottom: 20 }}>
              {(["overview", "income", "table"] as const).map((t) => (
                <button key={t} style={tabStyle(t)} onClick={() => setTab(t)}>
                  {t === "overview" ? "Portfolio Growth" : t === "income" ? "Income vs Spend" : "Year-by-Year"}
                </button>
              ))}
            </div>

            {tab === "overview" && (
              <div style={{ background: "rgba(255,255,255,0.02)", border: "1px solid rgba(255,255,255,0.06)", borderRadius: 16, padding: 24 }}>
                <div style={{ fontSize: 13, color: "#94a3b8", marginBottom: 16 }}>
                  Portfolio Buckets Over Time · projected to age 100 · Cash refilled from bonds + equity every 5 years
                </div>
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
                    <XAxis dataKey="age" stroke="#334155" tick={{ fill: "#475569", fontSize: 11, fontFamily: "DM Mono" }}
                      label={{ value: "Age", position: "insideBottom", offset: -2, fill: "#475569", fontSize: 11 }} />
                    <YAxis stroke="#334155" tick={{ fill: "#475569", fontSize: 11, fontFamily: "DM Mono" }} tickFormatter={(v: number) => fmt(v)} />
                    <Tooltip content={<CustomTooltip />} />
                    <Legend wrapperStyle={{ fontSize: 11, fontFamily: "DM Mono", color: "#94a3b8" }} />
                    <Area type="monotone" dataKey="equity" name="Equity" stackId="1" stroke="#34d399" fill="url(#gEq)" strokeWidth={2} />
                    <Area type="monotone" dataKey="bonds" name="Bonds" stackId="1" stroke="#60a5fa" fill="url(#gBond)" strokeWidth={2} />
                    <Area type="monotone" dataKey="cash" name="Cash" stackId="1" stroke="#f0c040" fill="url(#gCash)" strokeWidth={2} />
                  </AreaChart>
                </ResponsiveContainer>

                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 12, marginTop: 20 }}>
                  {([5, 10, 20] as const).map((y) => {
                    const d = projection[y];
                    if (!d) return null;
                    const grew = d.total > totalPortfolio;
                    return (
                      <div key={y} style={{ background: "rgba(255,255,255,0.03)", borderRadius: 10, padding: "14px 16px", border: `1px solid ${grew ? "rgba(52,211,153,0.2)" : "rgba(248,113,113,0.2)"}` }}>
                        <div style={{ fontSize: 10, color: "#64748b", textTransform: "uppercase", letterSpacing: "0.1em", fontFamily: "DM Mono", marginBottom: 4 }}>Year +{y} · Age {d.age}</div>
                        <div style={{ fontSize: 18, fontWeight: 800, color: grew ? "#34d399" : "#f87171", fontFamily: "DM Mono" }}>{fmt(d.total)}</div>
                        <div style={{ fontSize: 10, color: "#475569", marginTop: 4 }}>{grew ? "▲" : "▼"} {fmt(Math.abs(d.total - totalPortfolio))} vs start</div>
                        <div style={{ fontSize: 10, color: "#64748b" }}>Invest return: {fmt(d.totalReturn)}</div>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}

            {tab === "income" && (
              <div style={{ background: "rgba(255,255,255,0.02)", border: "1px solid rgba(255,255,255,0.06)", borderRadius: 16, padding: 24 }}>
                <div style={{ fontSize: 13, color: "#94a3b8", marginBottom: 16 }}>Income Sources vs. Spending (inflation-adjusted, nominal dollars)</div>
                <ResponsiveContainer width="100%" height={300}>
                  <LineChart data={projection} margin={{ top: 10, right: 10, left: 10, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.04)" />
                    <XAxis dataKey="age" stroke="#334155" tick={{ fill: "#475569", fontSize: 11, fontFamily: "DM Mono" }} />
                    <YAxis stroke="#334155" tick={{ fill: "#475569", fontSize: 11, fontFamily: "DM Mono" }} tickFormatter={(v: number) => fmt(v)} />
                    <Tooltip content={<CustomTooltip />} />
                    <Legend wrapperStyle={{ fontSize: 11, fontFamily: "DM Mono" }} />
                    <Line type="monotone" dataKey="spend" name="Total Spending" stroke="#f87171" strokeWidth={2} dot={false} />
                    <Line type="monotone" dataKey="totalReturn" name="Investment Return" stroke="#34d399" strokeWidth={2} dot={false} />
                    <Line type="monotone" dataKey="rental" name="Rental Income" stroke="#f0c040" strokeWidth={1.5} strokeDasharray="5 3" dot={false} />
                    <Line type="monotone" dataKey="ss" name="Social Security" stroke="#a78bfa" strokeWidth={1.5} strokeDasharray="5 3" dot={false} />
                    <ReferenceLine x={socialSecurityAge} stroke="#a78bfa" strokeDasharray="4 4"
                      label={{ value: `SS @ ${socialSecurityAge}`, fill: "#a78bfa", fontSize: 10, fontFamily: "DM Mono" }} />
                  </LineChart>
                </ResponsiveContainer>

                <div style={{ marginTop: 20, display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
                  <div style={{ background: "rgba(255,255,255,0.03)", borderRadius: 10, padding: "14px 16px" }}>
                    <div style={{ fontSize: 11, color: "#64748b", fontFamily: "DM Mono", marginBottom: 8, textTransform: "uppercase" }}>Year 1 Income Breakdown</div>
                    {(
                      [
                        ["Bond Gains", fmt(bondAmt * bondReturn / 100), "#60a5fa"],
                        ["Equity Gains", fmt(equityAmt * equityReturn / 100), "#34d399"],
                        ["Rental Income", fmt(rentalIncome), "#f0c040"],
                        ["Social Security", retireAge >= socialSecurityAge ? fmt(socialSecurityAmt) : "Not yet", "#a78bfa"],
                      ] as [string, string, string][]
                    ).map(([l, v, c]) => (
                      <div key={l} style={{ display: "flex", justifyContent: "space-between", marginBottom: 6, fontSize: 13 }}>
                        <span style={{ color: "#94a3b8" }}>{l}</span>
                        <span style={{ color: c, fontFamily: "DM Mono", fontWeight: 700 }}>{v}</span>
                      </div>
                    ))}
                    <div style={{ borderTop: "1px solid rgba(255,255,255,0.08)", paddingTop: 8, marginTop: 4, display: "flex", justifyContent: "space-between", fontSize: 14 }}>
                      <span style={{ color: "#e2e8f0" }}>vs. Annual Spending</span>
                      <span style={{ color: "#f87171", fontFamily: "DM Mono", fontWeight: 800 }}>{fmt(annualSpend)}</span>
                    </div>
                  </div>
                  <div style={{ background: "rgba(255,255,255,0.03)", borderRadius: 10, padding: "14px 16px" }}>
                    <div style={{ fontSize: 11, color: "#64748b", fontFamily: "DM Mono", marginBottom: 8, textTransform: "uppercase" }}>Bucket Strategy — How it Works</div>
                    {(
                      [
                        ["Year 0", `Set aside ${fmt(initialCash)} as cash (5-yr net reserve)`, "#f0c040"],
                        ["Years 1–5", "Spend from cash. Bonds + equity grow untouched.", "#94a3b8"],
                        ["End of Yr 5", "Withdraw next 5 yrs of expenses from investment pot.", "#34d399"],
                        ["Repeat", "Cash refilled every 5 years. Pot keeps compounding.", "#60a5fa"],
                      ] as [string, string, string][]
                    ).map(([l, v, c]) => (
                      <div key={l} style={{ display: "flex", gap: 10, marginBottom: 10 }}>
                        <span style={{ color: c, fontFamily: "DM Mono", fontSize: 11, fontWeight: 700, flexShrink: 0, minWidth: 74 }}>{l}</span>
                        <span style={{ color: "#64748b", fontSize: 12, lineHeight: 1.4 }}>{v}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {tab === "table" && (
              <div style={{ background: "rgba(255,255,255,0.02)", border: "1px solid rgba(255,255,255,0.06)", borderRadius: 16, padding: 24 }}>
                <div style={{ fontSize: 13, color: "#94a3b8", marginBottom: 16 }}>
                  Year-by-Year Projection · Green rows = cash refill from bonds + equity
                </div>
                <div style={{ overflowX: "auto" }}>
                  <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 12, fontFamily: "DM Mono" }}>
                    <thead>
                      <tr style={{ borderBottom: "1px solid rgba(240,192,64,0.3)" }}>
                        {["Yr", "Age", "Bonds", "Equity", "Cash", "Total", "Return", "Spend", "SS"].map((h) => (
                          <th key={h} style={{ padding: "8px 10px", color: "#f0c040", textAlign: "right", fontWeight: 600, fontSize: 10, letterSpacing: "0.05em" }}>{h}</th>
                        ))}
                      </tr>
                    </thead>
                    <tbody>
                      {projection.map((r) => {
                        const isGood = r.total >= totalPortfolio;
                        const isRefillYear = (r.yr + 1) % 5 === 0 && r.yr < projectionYears - 1;
                        return (
                          <tr key={r.yr} style={{
                            borderBottom: "1px solid rgba(255,255,255,0.04)",
                            background: isRefillYear ? "rgba(52,211,153,0.06)" : "transparent",
                          }}>
                            <td style={{ padding: "7px 10px", color: isRefillYear ? "#34d399" : "#64748b", textAlign: "right", fontWeight: isRefillYear ? 700 : 400 }}>{r.yr + 1}</td>
                            <td style={{ padding: "7px 10px", color: "#e2e8f0", textAlign: "right", fontWeight: 700 }}>{r.age}</td>
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

            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, marginTop: 16 }}>
              <div style={{ background: "rgba(255,255,255,0.02)", border: "1px solid rgba(255,255,255,0.06)", borderRadius: 12, padding: 18 }}>
                <div style={{ fontSize: 11, color: "#f0c040", fontFamily: "DM Mono", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: 10 }}>Investment Vehicles (Reference)</div>
                <div style={{ fontSize: 12, color: "#94a3b8", lineHeight: 1.8 }}>
                  <strong style={{ color: "#e2e8f0" }}>Bonds:</strong> 10-yr Treasuries, I-bonds, TIPS, investment-grade corporates.<br />
                  <strong style={{ color: "#e2e8f0" }}>Equity:</strong> VTSAX / VOO (total market index), dividend ETFs (VYM, SCHD).<br />
                  <strong style={{ color: "#e2e8f0" }}>Tax-efficient:</strong> Municipal bonds, Roth conversions post-retire, qualified dividends.<br />
                  <strong style={{ color: "#e2e8f0" }}>SS tip:</strong> Delaying to age 70 yields ~24% more than the age 67 payout.
                </div>
              </div>
              <div style={{ background: "rgba(255,255,255,0.02)", border: "1px solid rgba(255,255,255,0.06)", borderRadius: 12, padding: 18 }}>
                <div style={{ fontSize: 11, color: "#f0c040", fontFamily: "DM Mono", textTransform: "uppercase", letterSpacing: "0.1em", marginBottom: 10 }}>Your Scenario at a Glance</div>
                <div style={{ fontSize: 12, color: "#94a3b8", lineHeight: 1.9 }}>
                  <span style={{ color: "#60a5fa", fontFamily: "DM Mono" }}>{fmt(bondAmt)}</span> bonds · <span style={{ color: "#34d399", fontFamily: "DM Mono" }}>{fmt(equityAmt)}</span> equity<br />
                  Rental covers <strong style={{ color: "#e2e8f0" }}>{((rentalIncome / annualSpend) * 100).toFixed(0)}%</strong> of spend · SS at <strong style={{ color: "#e2e8f0" }}>age {socialSecurityAge}</strong><br />
                  Initial cash reserve: <strong style={{ color: "#f0c040", fontFamily: "DM Mono" }}>{fmt(initialCash)}</strong> (5-yr net)<br />
                  Portfolio at 25 yrs: <strong style={{ color: endPortfolio > totalPortfolio ? "#34d399" : "#f87171", fontFamily: "DM Mono" }}>{fmt(endPortfolio)}</strong>
                  {endPortfolio > totalPortfolio ? " — Growing" : " — Declining"}
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
