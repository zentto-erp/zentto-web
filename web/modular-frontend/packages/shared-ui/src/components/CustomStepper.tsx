"use client";

import * as React from "react";
import { styled } from "@mui/material/styles";
import Stack from "@mui/material/Stack";
import Stepper from "@mui/material/Stepper";
import Step from "@mui/material/Step";
import StepLabel from "@mui/material/StepLabel";
import StepConnector, {
  stepConnectorClasses,
} from "@mui/material/StepConnector";
import { StepIconProps } from "@mui/material/StepIcon";

// ─── Conector con gradiente entre los pasos ────────────────────

const ColorlibConnector = styled(StepConnector)(({ theme }) => ({
  [`&.${stepConnectorClasses.alternativeLabel}`]: {
    top: 22,
  },
  [`&.${stepConnectorClasses.active}`]: {
    [`& .${stepConnectorClasses.line}`]: {
      backgroundImage:
        "linear-gradient(95deg, #e04a48 0%, #aa1816 50%, #7a100e 100%)",
    },
  },
  [`&.${stepConnectorClasses.completed}`]: {
    [`& .${stepConnectorClasses.line}`]: {
      backgroundImage:
        "linear-gradient(95deg, #e04a48 0%, #aa1816 50%, #7a100e 100%)",
    },
  },
  [`& .${stepConnectorClasses.line}`]: {
    height: 3,
    border: 0,
    backgroundColor:
      theme.palette.mode === "dark" ? theme.palette.grey[800] : "#eaeaf0",
    borderRadius: 1,
  },
}));

// ─── Icono circular con gradiente ──────────────────────────────

const ColorlibStepIconRoot = styled("div")<{
  ownerState: { completed?: boolean; active?: boolean };
}>(({ theme, ownerState }) => ({
  backgroundColor:
    theme.palette.mode === "dark" ? theme.palette.grey[700] : "#ccc",
  zIndex: 1,
  color: "#fff",
  width: 50,
  height: 50,
  display: "flex",
  borderRadius: "50%",
  justifyContent: "center",
  alignItems: "center",
  ...(ownerState.active && {
    backgroundImage:
      "linear-gradient(136deg, #e04a48 0%, #aa1816 50%, #7a100e 100%)",
    boxShadow: "0 4px 10px 0 rgba(0,0,0,.25)",
  }),
  ...(ownerState.completed && {
    backgroundImage:
      "linear-gradient(136deg, #e04a48 0%, #aa1816 50%, #7a100e 100%)",
  }),
}));

// ─── Props del CustomStepper ───────────────────────────────────

export interface StepDef {
  label: string;
  icon: React.ReactElement;
}

export interface CustomStepperProps {
  /** Paso activo (0-based) */
  activeStep: number;
  /** Definición de los pasos con label e icono */
  steps: StepDef[];
  /** Callback cuando se hace clic en un paso (opcional) */
  onStepClick?: (step: number) => void;
  /** Permite navegación no lineal entre pasos */
  nonLinear?: boolean;
}

/**
 * Stepper con estilo de gradiente, íconos personalizados y conector coloreado.
 * Inspirado en el diseño de SpainInside, adaptado a la marca DatqBox.
 */
export default function CustomStepper({
  activeStep,
  steps,
  onStepClick,
  nonLinear = false,
}: CustomStepperProps) {
  // Construir el mapa de íconos dinámicamente a partir de steps
  function StepIcon(props: StepIconProps) {
    const { active, completed, className, icon } = props;
    const idx = Number(icon) - 1;
    return (
      <ColorlibStepIconRoot
        ownerState={{ completed, active }}
        className={className}
      >
        {steps[idx]?.icon ?? null}
      </ColorlibStepIconRoot>
    );
  }

  return (
    <Stack sx={{ width: "100%" }} spacing={4}>
      <Stepper
        alternativeLabel
        activeStep={activeStep}
        connector={<ColorlibConnector />}
        nonLinear={nonLinear}
      >
        {steps.map((step, index) => (
          <Step
            key={step.label}
            completed={nonLinear ? undefined : activeStep > index}
          >
            <StepLabel
              StepIconComponent={StepIcon}
              onClick={() => onStepClick?.(index)}
              sx={{ cursor: onStepClick ? "pointer" : "default" }}
            >
              {step.label}
            </StepLabel>
          </Step>
        ))}
      </Stepper>
    </Stack>
  );
}
