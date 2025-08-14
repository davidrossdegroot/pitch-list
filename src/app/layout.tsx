import type { Metadata } from "next";
import "../globals.css";

export const metadata: Metadata = {
  title: "DC Problems & Pitches",
  description: "A place to find meaningful work in DC",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="min-h-dvh bg-white text-gray-900 antialiased">
        {children}
      </body>
    </html>
  );
}
