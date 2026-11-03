/** Re-mounted on every navigation, so each page eases in (skipped under reduced motion). */
export default function Template({ children }: { children: React.ReactNode }) {
  return <div className="rise">{children}</div>;
}
