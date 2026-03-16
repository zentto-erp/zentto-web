"use client";

import React, { useState, useMemo } from "react";
import {
  Box,
  Paper,
  Typography,
  Button,
  TextField,
  Stack,
  Autocomplete,
  Chip,
  Alert,
  Card,
  CardContent,
  IconButton,
  Divider,
  CircularProgress,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import { DateCalendar } from "@mui/x-date-pickers/DateCalendar";
import { PickersDay, type PickersDayProps } from "@mui/x-date-pickers/PickersDay";
import { LocalizationProvider } from "@mui/x-date-pickers/LocalizationProvider";
import { AdapterDayjs } from "@mui/x-date-pickers/AdapterDayjs";
import SendIcon from "@mui/icons-material/Send";
import DeleteIcon from "@mui/icons-material/Delete";
import EventAvailableIcon from "@mui/icons-material/EventAvailable";
import WarningIcon from "@mui/icons-material/Warning";
import dayjs, { type Dayjs } from "dayjs";
import "dayjs/locale/es";
import { useEmpleadosList } from "../hooks/useEmpleados";
import {
  useDiasDisponibles,
  useCrearSolicitudVacaciones,
  useVacacionSolicitudesList,
} from "../hooks/useVacacionesSolicitudes";
import { formatCurrency } from "@zentto/shared-api";

dayjs.locale("es");

/** Generate workdays (Mon-Fri) between two dates inclusive */
function getWorkdaysBetween(start: string, end: string): string[] {
  const days: string[] = [];
  let current = dayjs(start);
  const endDate = dayjs(end);
  while (current.isBefore(endDate) || current.isSame(endDate, "day")) {
    const dow = current.day();
    if (dow !== 0 && dow !== 6) {
      days.push(current.format("YYYY-MM-DD"));
    }
    current = current.add(1, "day");
  }
  return days;
}

function SelectedDay(props: PickersDayProps & { selectedDays: string[]; pendingDays: string[] }) {
  const { selectedDays, pendingDays, day, outsideCurrentMonth, ...other } = props;
  const dateStr = day.format("YYYY-MM-DD");
  const isSelected = selectedDays.includes(dateStr);
  const isPending = pendingDays.includes(dateStr);
  const isWeekend = day.day() === 0 || day.day() === 6;

  return (
    <PickersDay
      {...other}
      day={day}
      outsideCurrentMonth={outsideCurrentMonth}
      sx={{
        ...(isSelected && {
          bgcolor: "primary.main",
          color: "white",
          "&:hover": { bgcolor: "primary.dark" },
          "&.Mui-selected": { bgcolor: "primary.main" },
        }),
        ...(isPending && !isSelected && {
          bgcolor: "warning.main",
          color: "white",
          "&:hover": { bgcolor: "warning.dark" },
        }),
        ...(isWeekend && !isSelected && !isPending && {
          color: "text.disabled",
          bgcolor: "action.hover",
        }),
      }}
    />
  );
}

export default function VacacionesCalendarPage() {
  const [selectedEmployee, setSelectedEmployee] = useState<any>(null);
  const [selectedDays, setSelectedDays] = useState<string[]>([]);
  const [notes, setNotes] = useState("");
  const [searchInput, setSearchInput] = useState("");
  const [successMsg, setSuccessMsg] = useState("");

  const cedula = selectedEmployee?.CEDULA ?? selectedEmployee?.cedula ?? selectedEmployee?.EmployeeCode ?? null;
  const nombreEmpleado = selectedEmployee?.NOMBRE ?? selectedEmployee?.nombre ?? selectedEmployee?.EmployeeName ?? "";

  const empleados = useEmpleadosList({ status: "ACTIVO", search: searchInput || undefined, limit: 20 });
  const diasDisponibles = useDiasDisponibles(cedula);
  const crearSolicitud = useCrearSolicitudVacaciones();

  // Query pending requests for selected employee
  const pendingRequests = useVacacionSolicitudesList(
    cedula ? { employeeCode: cedula, status: "PENDIENTE", limit: 50 } : undefined
  );

  const pendingRows: any[] = useMemo(() => {
    if (!pendingRequests.data) return [];
    const r = pendingRequests.data;
    return r?.rows ?? r?.data ?? (Array.isArray(r) ? r : []);
  }, [pendingRequests.data]);

  // Extract workdays from all pending requests
  const pendingDays = useMemo(() => {
    const allDays: string[] = [];
    for (const req of pendingRows) {
      const start = req.StartDate ?? req.startDate;
      const end = req.EndDate ?? req.endDate;
      if (start && end) {
        allDays.push(...getWorkdaysBetween(start, end));
      }
    }
    return Array.from(new Set(allDays));
  }, [pendingRows]);

  const empleadoOptions = useMemo(() => {
    if (Array.isArray(empleados.data)) return empleados.data;
    return empleados.data?.rows ?? [];
  }, [empleados.data]);

  const diasInfo = diasDisponibles.data;
  const diasRestantes = (diasInfo?.DiasDisponibles ?? 15) - selectedDays.length;

  const handleDayClick = (date: Dayjs) => {
    const dateStr = date.format("YYYY-MM-DD");
    const isWeekend = date.day() === 0 || date.day() === 6;
    if (isWeekend) return;

    setSelectedDays((prev) => {
      if (prev.includes(dateStr)) {
        return prev.filter((d) => d !== dateStr);
      }
      if (diasRestantes <= 0 && !prev.includes(dateStr)) return prev;
      return [...prev, dateStr].sort();
    });
  };

  const handleRemoveDay = (dateStr: string) => {
    setSelectedDays((prev) => prev.filter((d) => d !== dateStr));
  };

  const handleSubmit = async () => {
    if (!cedula || selectedDays.length === 0) return;

    const sortedDays = [...selectedDays].sort();
    const startDate = sortedDays[0];
    const endDate = sortedDays[sortedDays.length - 1];

    // Determine if partial: if days are non-consecutive, it's partial
    const isPartial = sortedDays.length > 1 && (() => {
      for (let i = 1; i < sortedDays.length; i++) {
        const prev = dayjs(sortedDays[i - 1]);
        const curr = dayjs(sortedDays[i]);
        const diff = curr.diff(prev, "day");
        // Allow weekends between consecutive workdays
        if (diff > 3) return true;
      }
      return false;
    })();

    await crearSolicitud.mutateAsync({
      employeeCode: cedula,
      startDate,
      endDate,
      totalDays: sortedDays.length,
      isPartial,
      notes: notes || undefined,
      days: sortedDays.map((d) => ({ date: d, dayType: "COMPLETO" })),
    });

    setSuccessMsg("Solicitud de vacaciones enviada exitosamente");
    setSelectedDays([]);
    setNotes("");
    setTimeout(() => setSuccessMsg(""), 5000);
  };

  return (
    <LocalizationProvider dateAdapter={AdapterDayjs} adapterLocale="es">
      <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
        <Typography variant="h6" fontWeight={600} mb={2}>
          Solicitar Vacaciones
        </Typography>

        {successMsg && <Alert severity="success" sx={{ mb: 2 }}>{successMsg}</Alert>}

        {/* Employee selector */}
        <Paper sx={{ p: 2, mb: 3 }}>
          <Autocomplete
            options={empleadoOptions}
            getOptionLabel={(opt: any) => {
              const ced = opt.CEDULA ?? opt.cedula ?? opt.EmployeeCode ?? "";
              const nom = opt.NOMBRE ?? opt.nombre ?? opt.EmployeeName ?? "";
              return `${ced} - ${nom}`;
            }}
            value={selectedEmployee}
            onChange={(_e, val) => {
              setSelectedEmployee(val);
              setSelectedDays([]);
            }}
            inputValue={searchInput}
            onInputChange={(_e, val) => setSearchInput(val)}
            loading={empleados.isLoading}
            renderInput={(params) => (
              <TextField {...params} label="Seleccionar Empleado" placeholder="Buscar por cédula o nombre..." />
            )}
            isOptionEqualToValue={(opt, val) =>
              (opt.CEDULA ?? opt.cedula) === (val.CEDULA ?? val.cedula)
            }
          />

          {cedula && diasInfo && (
            <Stack direction="row" spacing={3} mt={2} flexWrap="wrap">
              <Chip
                icon={<EventAvailableIcon />}
                label={`Días disponibles: ${diasInfo.DiasDisponibles}`}
                color="primary"
                variant="outlined"
              />
              <Chip label={`Años de servicio: ${diasInfo.AnosServicio}`} variant="outlined" />
              <Chip label={`Días tomados: ${diasInfo.DiasTomados}`} variant="outlined" />
              <Chip label={`Solicitudes pendientes: ${diasInfo.DiasPendientes} días`} variant="outlined" color="warning" />
            </Stack>
          )}
        </Paper>

        {/* Pending requests alert */}
        {cedula && pendingRows.length > 0 && (
          <Alert severity="warning" icon={<WarningIcon />} sx={{ mb: 3 }}>
            <Typography variant="body2" fontWeight={600} gutterBottom>
              Este empleado tiene {pendingRows.length} solicitud(es) pendiente(s):
            </Typography>
            {pendingRows.map((req: any) => (
              <Typography key={req.RequestId ?? req.requestId} variant="body2">
                #{req.RequestId ?? req.requestId} — {req.StartDate ?? req.startDate} al {req.EndDate ?? req.endDate} ({req.TotalDays ?? req.totalDays} días)
              </Typography>
            ))}
            <Stack direction="row" spacing={2} mt={1}>
              <Chip size="small" sx={{ bgcolor: "warning.main", color: "white" }} label="Días previamente solicitados" />
              <Chip size="small" sx={{ bgcolor: "primary.main", color: "white" }} label="Nueva selección" />
            </Stack>
          </Alert>
        )}

        {cedula && (
          <Grid container spacing={3}>
            {/* Calendar */}
            <Grid size={{ xs: 12, md: 7 }}>
              <Paper sx={{ p: 2 }}>
                <Typography variant="subtitle1" fontWeight={600} mb={1}>
                  Seleccione los días de vacaciones
                </Typography>
                <Typography variant="body2" color="text.secondary" mb={2}>
                  Haga clic en los días laborables para seleccionar/deseleccionar. Los fines de semana están deshabilitados.
                </Typography>

                <DateCalendar
                  onChange={(date) => date && handleDayClick(date)}
                  slots={{ day: SelectedDay as any }}
                  slotProps={{ day: { selectedDays, pendingDays } as any }}
                  sx={{ width: "100%" }}
                />
              </Paper>
            </Grid>

            {/* Summary panel */}
            <Grid size={{ xs: 12, md: 5 }}>
              <Card sx={{ height: "100%" }}>
                <CardContent>
                  <Typography variant="subtitle1" fontWeight={600} mb={2}>
                    Resumen de Solicitud
                  </Typography>

                  <Box sx={{ mb: 2 }}>
                    <Typography variant="body2" color="text.secondary">Empleado</Typography>
                    <Typography variant="body1" fontWeight={500}>{nombreEmpleado}</Typography>
                  </Box>

                  <Divider sx={{ my: 2 }} />

                  <Box sx={{ mb: 2 }}>
                    <Typography variant="body2" color="text.secondary" mb={1}>
                      Días seleccionados ({selectedDays.length})
                    </Typography>

                    {selectedDays.length === 0 ? (
                      <Typography variant="body2" color="text.disabled">
                        Ningún día seleccionado
                      </Typography>
                    ) : (
                      <Stack spacing={0.5} sx={{ maxHeight: 200, overflow: "auto" }}>
                        {selectedDays.map((d) => (
                          <Stack key={d} direction="row" alignItems="center" justifyContent="space-between">
                            <Typography variant="body2">
                              {dayjs(d).format("dddd, D [de] MMMM YYYY")}
                            </Typography>
                            <IconButton size="small" onClick={() => handleRemoveDay(d)}>
                              <DeleteIcon fontSize="small" />
                            </IconButton>
                          </Stack>
                        ))}
                      </Stack>
                    )}
                  </Box>

                  <Divider sx={{ my: 2 }} />

                  <Stack spacing={1} mb={2}>
                    <Stack direction="row" justifyContent="space-between">
                      <Typography variant="body2" color="text.secondary">Total días solicitados</Typography>
                      <Typography variant="body1" fontWeight={600}>{selectedDays.length}</Typography>
                    </Stack>
                    <Stack direction="row" justifyContent="space-between">
                      <Typography variant="body2" color="text.secondary">Días restantes</Typography>
                      <Typography
                        variant="body1"
                        fontWeight={600}
                        color={diasRestantes < 0 ? "error" : "success.main"}
                      >
                        {diasRestantes}
                      </Typography>
                    </Stack>
                  </Stack>

                  <TextField
                    label="Notas (opcional)"
                    multiline
                    rows={2}
                    fullWidth
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    sx={{ mb: 2 }}
                  />

                  <Button
                    variant="contained"
                    fullWidth
                    size="large"
                    startIcon={crearSolicitud.isPending ? <CircularProgress size={20} color="inherit" /> : <SendIcon />}
                    onClick={handleSubmit}
                    disabled={selectedDays.length === 0 || diasRestantes < 0 || crearSolicitud.isPending}
                  >
                    Solicitar Vacaciones
                  </Button>

                  {crearSolicitud.isError && (
                    <Alert severity="error" sx={{ mt: 2 }}>
                      {(crearSolicitud.error as Error)?.message || "Error al enviar solicitud"}
                    </Alert>
                  )}
                </CardContent>
              </Card>
            </Grid>
          </Grid>
        )}
      </Box>
    </LocalizationProvider>
  );
}
