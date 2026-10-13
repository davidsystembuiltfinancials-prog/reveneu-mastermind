import React, { useEffect, useMemo, useState } from "react";
import { createRoot } from "react-dom/client";
import archivesUrl from "./assets/rooms/archives.png";
import archivistSheet from "./assets/agents/sheets/archivist-sheet.png";
import attendantSheet from "./assets/agents/sheets/attendant-sheet.png";
import auditSheet from "./assets/agents/sheets/audit-sheet.png";
import armoryUrl from "./assets/rooms/armory.png";
import bridgeUrl from "./assets/rooms/bridge.png";
import commsUrl from "./assets/rooms/comms.png";
import commSheet from "./assets/agents/sheets/comm-sheet.png";
import engineerASheet from "./assets/agents/sheets/engineer-a-sheet.png";
import engineerBSheet from "./assets/agents/sheets/engineer-b-sheet.png";
import factory1Url from "./assets/rooms/factory1.png";
import factory2Url from "./assets/rooms/factory2.png";
import mediaSheet from "./assets/agents/sheets/media-a-sheet.png";
import overseerSheet from "./assets/agents/sheets/overseer-sheet.png";
import mediaUrl from "./assets/rooms/media.png";
import quartersUrl from "./assets/rooms/quarters.png";
import radarUrl from "./assets/rooms/radar.png";
import researchUrl from "./assets/rooms/research.png";
import researcherASheet from "./assets/agents/sheets/research-a-sheet.png";
import researcherBSheet from "./assets/agents/sheets/research-b-sheet.png";
import signalSheet from "./assets/agents/sheets/signal-sheet.png";
import treasuryUrl from "./assets/rooms/treasury.png";
import wardenSheet from "./assets/agents/sheets/warden-sheet.png";
import warUrl from "./assets/rooms/war.png";
import "./styles.css";

type Room = {
  id: string;
  name: string;
  band: "upper" | "middle" | "lower";
  role: string;
  machinery: string;
  alert: string;
  accent: string;
  feed: string;
  image: string;
};

type Agent = {
  id: string;
  label: string;
  role: string;
  room: string;
  x: number;
  y: number;
  accent: string;
  activity: "idle" | "walk";
  direction: "front" | "back" | "left" | "right";
  line: string;
  sheet: string;
  route: Array<[number, number]>;
  pace: number;
  phase: number;
};

type AgentPose = Agent & {
  liveX: number;
  liveY: number;
  liveActivity: Agent["activity"];
  liveDirection: Agent["direction"];
  step: number;
};

const frameSize = 40;
const sheetColumns = 4;
const sheetRows = 8;

const rooms: Room[] = [
  { id: "bridge", name: "Bridge", band: "upper", role: "Station Control", machinery: "command throne / holographic map", alert: "AI governor synced", accent: "#44f2c4", feed: "Orbital vector stable", image: bridgeUrl },
  { id: "research", name: "Research Lab", band: "upper", role: "Unknowns", machinery: "scanners / specimen rigs", alert: "scan batch 77%", accent: "#7df6ff", feed: "Anomaly culture cooled", image: researchUrl },
  { id: "media", name: "Media Room", band: "upper", role: "Narrative Fabrication", machinery: "screen wall / music rigs", alert: "asset render live", accent: "#ee5fff", feed: "Signal cut arranged", image: mediaUrl },
  { id: "war", name: "War Room", band: "upper", role: "Conflict Models", machinery: "red strategy table", alert: "risk fan active", accent: "#ff4545", feed: "Countermove queued", image: warUrl },
  { id: "factory1", name: "Factory I", band: "middle", role: "Print Line", machinery: "print / packing line", alert: "conveyor nominal", accent: "#ffc65a", feed: "Shell batch sealed", image: factory1Url },
  { id: "comms", name: "Comms Hub", band: "middle", role: "Switching", machinery: "switchboard / relays", alert: "carrier locked", accent: "#37f7a4", feed: "Long-band ping returned", image: commsUrl },
  { id: "treasury", name: "Treasury", band: "middle", role: "Ledger Core", machinery: "vault logic / account coil", alert: "audit seal hot", accent: "#ffe06b", feed: "Escrow pulse verified", image: treasuryUrl },
  { id: "factory2", name: "Factory II", band: "middle", role: "Assembly", machinery: "robotic conveyors", alert: "armature cycling", accent: "#ff9f43", feed: "Servo lane balanced", image: factory2Url },
  { id: "radar", name: "Radar", band: "lower", role: "Perimeter", machinery: "radar table / sweep lens", alert: "sweep loop green", accent: "#41ffd2", feed: "Debris echo cleared", image: radarUrl },
  { id: "archives", name: "Archives", band: "lower", role: "Memory", machinery: "memory stacks", alert: "cold tape awake", accent: "#b288ff", feed: "Yearblock indexed", image: archivesUrl },
  { id: "armory", name: "Armory", band: "lower", role: "Tools", machinery: "tool benches / lockers", alert: "warden review", accent: "#ff6666", feed: "Repair set released", image: armoryUrl },
  { id: "quarters", name: "Quarters", band: "lower", role: "Recovery", machinery: "recovery pods", alert: "pods breathing", accent: "#7fff8a", feed: "Attendant cycle quiet", image: quartersUrl }
];

const agents: Agent[] = [
  { id: "overseer", label: "OSR", role: "Overseer", room: "bridge", x: 50, y: 50, accent: "#d8fff4", activity: "walk", direction: "front", line: "route all", sheet: overseerSheet, route: [[50, 50], [58, 46], [52, 58], [44, 53]], pace: 2100, phase: 0 },
  { id: "research-a", label: "R1", role: "Researcher", room: "research", x: 38, y: 55, accent: "#7df6ff", activity: "walk", direction: "right", line: "sample cold", sheet: researcherASheet, route: [[38, 55], [45, 46], [35, 39], [30, 57]], pace: 2450, phase: 0.2 },
  { id: "research-b", label: "R2", role: "Researcher", room: "research", x: 66, y: 38, accent: "#7df6ff", activity: "walk", direction: "left", line: "scan", sheet: researcherBSheet, route: [[66, 38], [58, 49], [69, 58], [74, 43]], pace: 2300, phase: 0.55 },
  { id: "media-a", label: "MO", role: "Media Operator", room: "media", x: 55, y: 48, accent: "#ee5fff", activity: "walk", direction: "back", line: "splice ok", sheet: mediaSheet, route: [[55, 48], [42, 55], [50, 65], [64, 53]], pace: 2600, phase: 0.35 },
  { id: "audit", label: "AU", role: "Auditor", room: "treasury", x: 47, y: 58, accent: "#ffe06b", activity: "walk", direction: "front", line: "hash good", sheet: auditSheet, route: [[47, 58], [57, 49], [50, 38], [39, 48]], pace: 2750, phase: 0.1 },
  { id: "engineer-a", label: "E1", role: "Engineer", room: "factory1", x: 36, y: 47, accent: "#ffc65a", activity: "walk", direction: "right", line: "belt up", sheet: engineerASheet, route: [[36, 47], [52, 48], [61, 57], [31, 59]], pace: 1900, phase: 0.7 },
  { id: "engineer-b", label: "E2", role: "Engineer", room: "factory2", x: 70, y: 54, accent: "#ff9f43", activity: "walk", direction: "left", line: "arm set", sheet: engineerBSheet, route: [[70, 54], [58, 61], [49, 50], [63, 42]], pace: 2200, phase: 0.4 },
  { id: "comm", label: "CO", role: "Comms Officer", room: "comms", x: 48, y: 44, accent: "#37f7a4", activity: "walk", direction: "front", line: "carrier", sheet: commSheet, route: [[48, 44], [39, 53], [51, 62], [59, 48]], pace: 2500, phase: 0.25 },
  { id: "signal", label: "SW", role: "Signal Watcher", room: "radar", x: 52, y: 49, accent: "#41ffd2", activity: "walk", direction: "back", line: "sweep", sheet: signalSheet, route: [[52, 49], [61, 44], [57, 61], [44, 56], [42, 43]], pace: 2400, phase: 0.6 },
  { id: "archivist", label: "AR", role: "Archivist", room: "archives", x: 44, y: 53, accent: "#b288ff", activity: "walk", direction: "right", line: "index", sheet: archivistSheet, route: [[44, 53], [35, 61], [53, 62], [59, 45]], pace: 2850, phase: 0.15 },
  { id: "warden", label: "TW", role: "Tool Warden", room: "armory", x: 57, y: 45, accent: "#ff6666", activity: "walk", direction: "left", line: "bench", sheet: wardenSheet, route: [[57, 45], [47, 54], [58, 65], [68, 50]], pace: 2350, phase: 0.85 },
  { id: "attendant", label: "AT", role: "Attendant", room: "quarters", x: 62, y: 57, accent: "#7fff8a", activity: "walk", direction: "front", line: "rest", sheet: attendantSheet, route: [[62, 57], [52, 47], [61, 36], [72, 49]], pace: 2700, phase: 0.5 }
];

const animationRows = {
  "idle-front": 0,
  "idle-back": 1,
  "idle-left": 2,
  "idle-right": 3,
  "walk-front": 4,
  "walk-back": 5,
  "walk-left": 6,
  "walk-right": 7
} satisfies Record<`${Agent["activity"]}-${Agent["direction"]}`, number>;

function smoothStep(value: number) {
  return value * value * (3 - 2 * value);
}

function getDirection(dx: number, dy: number): Agent["direction"] {
  if (Math.abs(dx) > Math.abs(dy)) {
    return dx < 0 ? "left" : "right";
  }

  return dy < 0 ? "back" : "front";
}

function getPose(agent: Agent, clock: number): AgentPose {
  const route = agent.route;
  const segment = (clock / agent.pace + agent.phase) % route.length;
  const index = Math.floor(segment);
  const nextIndex = (index + 1) % route.length;
  const local = segment - index;
  const eased = smoothStep(local);
  const [x1, y1] = route[index];
  const [x2, y2] = route[nextIndex];
  const dx = x2 - x1;
  const dy = y2 - y1;
  const pauseWindow = local < 0.12 || local > 0.9;
  const liveActivity = pauseWindow ? "idle" : "walk";

  return {
    ...agent,
    liveX: x1 + dx * eased,
    liveY: y1 + dy * eased,
    liveActivity,
    liveDirection: liveActivity === "idle" ? agent.direction : getDirection(dx, dy),
    step: local
  };
}

function SpriteAnimator({ agent, clock }: { agent: AgentPose; clock: number }) {
  const row = animationRows[`${agent.liveActivity}-${agent.liveDirection}`];
  const frameDuration = agent.liveActivity === "idle" ? 260 : 120;
  const frameIndex = Math.floor(clock / frameDuration + agent.phase * 4) % sheetColumns;

  return (
    <span
      className="agent-sprite"
      style={
        {
          width: frameSize,
          height: frameSize,
          backgroundImage: `url(${agent.sheet})`,
          backgroundRepeat: "no-repeat",
          backgroundSize: `${frameSize * sheetColumns}px ${frameSize * sheetRows}px`,
          backgroundPosition: `${-frameIndex * frameSize}px ${-row * frameSize}px`
        } as React.CSSProperties
      }
    />
  );
}

function App() {
  const [selectedId, setSelectedId] = useState("bridge");
  const [hoveredId, setHoveredId] = useState<string | null>(null);
  const [clock, setClock] = useState(0);
  const selected = rooms.find((room) => room.id === selectedId) ?? rooms[0];
  const activeRoom = rooms.find((room) => room.id === hoveredId) ?? selected;
  const roomAgents = useMemo(() => agents.filter((agent) => agent.room === activeRoom.id), [activeRoom.id]);
  const posedAgents = useMemo(() => agents.map((agent) => getPose(agent, clock)), [clock]);

  useEffect(() => {
    const id = window.setInterval(() => {
      setClock(performance.now());
    }, 90);

    return () => window.clearInterval(id);
  }, []);

  return (
    <main className="crt-shell">
      <div className="scanlines" />
      <header className="topbar">
        <div className="brand">
          <span className="brand-mark">ARES</span>
          <span>AI-RUN HABITAT OPS</span>
        </div>
        <div className="status-strip">
          <span>HULL 99.2</span>
          <span>O2 21.0</span>
          <span>CORE 06</span>
          <span>LAT 14MS</span>
          <span className="warn">RED ZONES 03</span>
        </div>
      </header>

      <section className="layout-grid">
        <aside className="panel roster">
          <div className="panel-title">Agent Cohort</div>
          {agents.map((agent) => (
            <button
              className={`agent-row ${agent.room === activeRoom.id ? "is-linked" : ""}`}
              key={agent.id}
              onMouseEnter={() => setHoveredId(agent.room)}
              onFocus={() => setHoveredId(agent.room)}
              onClick={() => setSelectedId(agent.room)}
            >
              <span className="agent-led" style={{ "--agent-color": agent.accent } as React.CSSProperties} />
              <span>
                <strong>{agent.label}</strong>
                <small>{agent.role}</small>
              </span>
              <em>{rooms.find((room) => room.id === agent.room)?.name}</em>
            </button>
          ))}
        </aside>

        <section className="station-stage" aria-label="ARES station tactical map">
          <div className="station-hull">
            <div className="data-trace trace-a" />
            <div className="data-trace trace-b" />
            <div className="corridor corridor-upper" />
            <div className="corridor corridor-mid" />
            <div className="corridor corridor-low" />
            <div className="shaft shaft-left" />
            <div className="shaft shaft-right" />
            <div className="room-grid">
              {rooms.map((room) => (
                <button
                  className={`room-plate ${selectedId === room.id ? "is-selected" : ""} ${hoveredId === room.id ? "is-hovered" : ""}`}
                  key={room.id}
                  onClick={() => setSelectedId(room.id)}
                  onMouseEnter={() => setHoveredId(room.id)}
                  onMouseLeave={() => setHoveredId(null)}
                  onFocus={() => setHoveredId(room.id)}
                  style={
                    {
                      "--accent": room.accent,
                      "--room-image": `url(${room.image})`
                    } as React.CSSProperties
                  }
                >
                  <span className="room-art" />
                  <span className="room-noise" />
                  <span className="door door-n" />
                  <span className="door door-s" />
                  <span className="door door-w" />
                  <span className="door door-e" />
                  <span className="room-label">{room.name}</span>
                  <span className="room-machinery">{room.role}</span>
                  {posedAgents
                    .filter((agent) => agent.room === room.id)
                    .map((agent) => (
                      <span
                        className={`agent-marker ${agent.liveActivity} facing-${agent.liveDirection}`}
                        key={agent.id}
                        style={
                          {
                            "--agent-color": agent.accent,
                            "--agent-x": `${agent.liveX}%`,
                            "--agent-y": `${agent.liveY}%`
                          } as React.CSSProperties
                        }
                      >
                        <SpriteAnimator agent={agent} clock={clock} />
                        <i>{agent.label}</i>
                        <b>{agent.line}</b>
                      </span>
                    ))}
                  {room.id === "factory1" || room.id === "factory2" ? <span className="conveyor" /> : null}
                  {room.id === "radar" ? <span className="radar-sweep" /> : null}
                  {room.id === "war" || room.id === "armory" ? <span className="red-zone" /> : null}
                </button>
              ))}
            </div>
          </div>
          <div className="selection-readout">
            <strong>{activeRoom.name}</strong>
            <span>{activeRoom.machinery}</span>
            <em>{activeRoom.alert}</em>
          </div>
        </section>

        <aside className="right-stack">
          <section className="panel ops">
            <div className="panel-title">Ops Console</div>
            <div className="ops-target" style={{ "--accent": activeRoom.accent } as React.CSSProperties}>
              <strong>{activeRoom.name}</strong>
              <span>{activeRoom.role}</span>
              <p>{activeRoom.machinery}</p>
            </div>
            <div className="meter-grid">
              <span><i style={{ width: "72%" }} /> Power</span>
              <span><i style={{ width: "88%" }} /> Sync</span>
              <span><i style={{ width: "41%" }} /> Risk</span>
            </div>
          </section>
          <section className="panel feed">
            <div className="panel-title">Feed</div>
            {[activeRoom.feed, "Corridor seals breathing", "Teal line handshake", "Noise floor acceptable", "Door seams nominal"].map((item, index) => (
              <p key={item}><span>{String(index + 1).padStart(2, "0")}</span>{item}</p>
            ))}
          </section>
          <section className="panel comms">
            <div className="panel-title">Comms</div>
            {roomAgents.length ? roomAgents.map((agent) => (
              <div className="comm-line" key={agent.id}>
                <strong>{agent.label}</strong>
                <span>{agent.line}</span>
              </div>
            )) : <div className="comm-line"><strong>SYS</strong><span>silent room</span></div>}
          </section>
        </aside>
      </section>

      <nav className="bottom-dock" aria-label="ARES dock controls">
        {["MAP", "COHORT", "POWER", "COMMS", "SCAN", "LOCK", "AUDIT", "PURGE"].map((item) => (
          <button key={item}>{item}</button>
        ))}
      </nav>
    </main>
  );
}

createRoot(document.getElementById("root")!).render(<App />);
