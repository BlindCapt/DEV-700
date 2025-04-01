import * as React from "react"
import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

import {
  Legend as RechartLegend,
  Tooltip as RechartTooltip,
  TooltipProps,
  ResponsiveContainer,
} from "recharts"

// Utilitaire de fusion de classes
function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

// Types pour la configuration des graphiques
export type ChartConfig = Record<
  string,
  {
    label: string
    color: string
  }
>

// Conteneur pour les graphiques
const ChartContainer = ({
  children,
  config,
  className,
  ...props
}: React.HTMLAttributes<HTMLDivElement> & {
  config?: ChartConfig
}) => {
  return (
    <div
      className={cn("relative h-full w-full", className)}
      style={
        config
          ? {
              // @ts-ignore -- CSS variables
              "--color-keys": Object.keys(config).join(" "),
              ...Object.entries(config).reduce(
                (acc, [key, { color }]) => ({
                  ...acc,
                  // @ts-ignore -- CSS variables
                  [`--color-${key}`]: color,
                }),
                {}
              ),
            }
          : {}
      }
      {...props}
    >
      {/* @ts-ignore -- Recharts type issues */}
      <ResponsiveContainer>{children}</ResponsiveContainer>
    </div>
  )
}

// Composant pour la légende
const ChartLegend = ({
  className,
  ...props
}: Omit<React.ComponentProps<typeof RechartLegend>, "className"> & {
  className?: string
}) => {
  return (
    // @ts-ignore -- Recharts type issues
    <RechartLegend
      verticalAlign="middle"
      align="right"
      width={100}
      layout="vertical"
      iconSize={10}
      iconType="circle"
      {...props}
    />
  )
}

// Contenu de la légende
const ChartLegendContent = ({
  className,
  nameKey = "key",
  ...props
}: {
  className?: string
  nameKey?: string
  payload?: Array<any>
}) => {
  const { payload } = props
  if (!payload || !payload.length) return null

  return (
    <div
      className={cn(
        "flex flex-col gap-2 rounded-md border bg-background p-2 text-xs",
        className
      )}
    >
      {payload.map((entry, index) => {
        const label = entry.value ?? entry[nameKey]
        const fill = entry.color

        return (
          <div key={`item-${index}`} className="flex items-center gap-1">
            <div
              className="h-2 w-2 rounded-full"
              style={{
                backgroundColor: fill,
              }}
            />
            <span className="text-muted-foreground">{label}</span>
          </div>
        )
      })}
    </div>
  )
}

// Tooltip pour les graphiques
const ChartTooltip = (props: React.ComponentProps<typeof RechartTooltip>) => {
  return (
    // @ts-ignore -- Recharts type issues
    <RechartTooltip
      cursor={{ stroke: "var(--border)" }}
      {...props}
    />
  )
}

// Contenu du tooltip
export interface ChartTooltipContentProps {
  className?: string
  active?: boolean
  payload?: Array<any>
  label?: string
  nameKey?: string
  valueKey?: string
  valueFormatter?: (value: number) => string
}

const ChartTooltipContent = ({
  className,
  active,
  payload,
  nameKey = "name",
  valueKey = "value",
  valueFormatter = (value: number) => value.toLocaleString(),
  ...props
}: ChartTooltipContentProps) => {
  if (!active || !payload || !payload.length) return null

  return (
    <div
      className={cn(
        "flex flex-col gap-2 rounded-md border bg-background p-2 text-xs shadow-md",
        className
      )}
      {...props}
    >
      <div className="flex justify-between gap-2">
        <p className="text-muted-foreground">{props.label}</p>
      </div>
      {payload.map((entry, index) => {
        const color = entry.color as string
        const name = entry.name
        const value = entry.value as number

        return (
          <div key={`item-${index}`} className="flex items-center gap-2">
            <div
              className="h-2 w-2 rounded-full"
              style={{
                backgroundColor: color,
              }}
            />
            <span className="text-muted-foreground">{name}:</span>
            <span>{valueFormatter(value)}</span>
          </div>
        )
      })}
    </div>
  )
}

// Export des composants
export {
  ChartContainer,
  ChartLegend,
  ChartLegendContent,
  ChartTooltip,
  ChartTooltipContent,
} 