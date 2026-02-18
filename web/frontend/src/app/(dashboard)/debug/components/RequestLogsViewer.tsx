'use client';

import React, { useState, useEffect } from 'react';
import {
  Box,
  Paper,
  Typography,
  TextField,
  Button,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Chip,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  IconButton,
  Tooltip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  CircularProgress,
  Tabs,
  Tab,
  Accordion,
  AccordionSummary,
  AccordionDetails,
} from '@mui/material';
import {
  FilterList as FilterListIcon,
  Clear as ClearIcon,
  Refresh as RefreshIcon,
  Delete as DeleteIcon,
  ExpandMore as ExpandMoreIcon,
  CheckCircle as CheckCircleIcon,
  Error as ErrorIcon,
  ContentCopy as ContentCopyIcon,
  Check as CheckIcon,
} from '@mui/icons-material';
import { useRequestLogger, LogFilters } from '@/app/hooks/useRequestLogger';
import { RequestLog } from '@/app/utils/requestLogger';
import { toast } from 'react-hot-toast';
import { Alert } from '@mui/material';

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;
  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`logs-tabpanel-${index}`}
      aria-labelledby={`logs-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ p: 2}}>{children}</Box>}
    </div>
  );
}

function extractEndpoint(url: string): string {
  try {
    const urlObj = new URL(url);
    return urlObj.pathname;
  } catch {
    const match = url.match(/\/[^?]*/);
    return match ? match[0] : url;
  }
}

export default function RequestLogsViewer() {
  const {
    logs,
    isLoading,
    loadLogs,
    loadLogsFromServer,
    loadStatsFromServer,
    filterLogs,
    clearOldLogs,
    clearAllLogs,
    getStats,
  } = useRequestLogger();

  const [filters, setFilters] = useState<LogFilters>({});
  const [selectedLog, setSelectedLog] = useState<RequestLog | null>(null);
  const [detailDialogOpen, setDetailDialogOpen] = useState(false);
  const [copied, setCopied] = useState(false);
  const [activeTab, setActiveTab] = useState(0);
  const [useServerLogs, setUseServerLogs] = useState(true);
  const [serverStats, setServerStats] = useState<any>(null);

  const stats = useServerLogs && serverStats ? serverStats : getStats();

  useEffect(() => {
    const loadData = async () => {
      if (useServerLogs) {
        await loadLogsFromServer(filters);
        const statsData = await loadStatsFromServer();
        if (statsData) {
          setServerStats(statsData);
        }
      } else {
        filterLogs(filters);
      }
    };
    loadData();
  }, [filters, useServerLogs, loadLogsFromServer, filterLogs, loadStatsFromServer]);

  const handleFilterChange = (key: keyof LogFilters, value: any) => {
    setFilters((prev) => ({
      ...prev,
      [key]: value === '' || value === null || value === undefined ? undefined : value,
    }));
  };

  const handleClearFilters = () => {
    setFilters({});
  };

 const handleViewDetails = (log: RequestLog) => {
    setSelectedLog(log);
    setDetailDialogOpen(true);
  };

  const handleCopyLog = () => {
    if (selectedLog) {
      navigator.clipboard.writeText(JSON.stringify(selectedLog, null, 2));
      toast.success('Log completo copiado');
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  const handleClearAll = () => {
    if (window.confirm('¿Eliminar TODOS los logs? Esta acción no se puede deshacer.')) {
      clearAllLogs();
      toast.success('Todos los logs han sido eliminados');
    }
  };

  const handleRefresh = async () => {
    if (useServerLogs) {
      await loadLogsFromServer(filters);
      const statsData = await loadStatsFromServer();
      if (statsData) {
        setServerStats(statsData);
      }
      toast.success('Logs actualizados');
    } else {
      loadLogs();
      toast.success('Logs actualizados desde localStorage');
    }
  };

  const filteredLogs = logs.filter((log) => {
    if (filters.method && log.method !== filters.method.toUpperCase()) return false;
    if (filters.endpoint) {
      const logEndpoint = extractEndpoint(log.url);
      if (!logEndpoint.includes(filters.endpoint)) return false;
    }
    if (filters.url && !log.url.includes(filters.url)) return false;
    if (filters.success !== undefined && log.success !== filters.success) return false;
    if (filters.userEmail && log.user.userEmail !== filters.userEmail) return false;
    if (filters.startDate && log.timestamp < filters.startDate) return false;
    if (filters.endDate && log.timestamp > filters.endDate) return false;
    return true;
  });

  const postPatchLogs = filteredLogs.filter(
    (log) => log.method === 'POST' || log.method === 'PATCH'
  );

  return (
    <Box sx={{ width: '100%' }}>
      {/* Estadísticas */}
      <Paper sx={{ p: 2, mb: 2 }}>
        <Typography variant="h6" gutterBottom>
          Estadísticas de Logs
        </Typography>
        <Stack direction="row" spacing={2} flexWrap="wrap" sx={{ mb: 2 }}>
          <Chip label={`Total: ${stats?.total || 0}`} color="primary" />
          <Chip
            label={`Exitosos: ${stats?.successful || 0}`}
            color="success"
            icon={<CheckCircleIcon />}
          />
          <Chip
            label={`Fallidos: ${stats?.failed || 0}`}
            color="error"
            icon={<ErrorIcon />}
          />
          {stats?.methods && Object.entries(stats.methods).map(([method, count]: any) => (
            <Chip key={method} label={`${method}: ${count}`} variant="outlined" />
          ))}
        </Stack>
      </Paper>

      {/* Filtros */}
      <Paper sx={{ p: 2, mb: 2 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
          <FilterListIcon sx={{ mr: 1 }} />
          <Typography variant="h6">Filtros</Typography>
          <Box sx={{ flexGrow: 1 }} />
          <Button
            startIcon={<RefreshIcon />}
            onClick={handleRefresh}
            size="small"
            sx={{ mr: 1 }}
          >
            Actualizar
          </Button>
          <Button
            startIcon={<ClearIcon />}
            onClick={handleClearFilters}
            size="small"
            variant="outlined"
          >
            Limpiar
          </Button>
        </Box>

        <Stack direction="row" spacing={2} flexWrap="wrap">
          <FormControl size="small" sx={{ minWidth: 100 }}>
            <InputLabel>Fuente</InputLabel>
            <Select
              value={useServerLogs ? 'server' : 'local'}
              label="Fuente"
              onChange={(e) => setUseServerLogs(e.target.value === 'server')}
            >
              <MenuItem value="server">SQLite (Servidor)</MenuItem>
              <MenuItem value="local">LocalStorage</MenuItem>
            </Select>
          </FormControl>

          <FormControl size="small" sx={{ minWidth: 100 }}>
            <InputLabel>Método</InputLabel>
            <Select
              value={filters.method || ''}
              label="Método"
              onChange={(e) => handleFilterChange('method', e.target.value)}
            >
              <MenuItem value="">Todos</MenuItem>
              <MenuItem value="POST">POST</MenuItem>
              <MenuItem value="PATCH">PATCH</MenuItem>
              <MenuItem value="GET">GET</MenuItem>
            </Select>
          </FormControl>

          <TextField
            size="small"
            label="Endpoint"
            value={filters.endpoint || ''}
            onChange={(e) => handleFilterChange('endpoint', e.target.value)}
            placeholder="/api/..."
          />

          <FormControl size="small" sx={{ minWidth: 100 }}>
            <InputLabel>Estado</InputLabel>
            <Select
              value={filters.success === undefined ? '' : String(filters.success)}
              label="Estado"
              onChange={(e) => {
                const value = e.target.value;
                if (value === '') handleFilterChange('success', undefined);
                else handleFilterChange('success', value === 'true');
              }}
            >
              <MenuItem value="">Todos</MenuItem>
              <MenuItem value="true">Exitosos</MenuItem>
              <MenuItem value="false">Fallidos</MenuItem>
            </Select>
          </FormControl>
        </Stack>
      </Paper>

      {/* Tabla de logs */}
      {isLoading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
          <CircularProgress />
        </Box>
      ) : postPatchLogs.length === 0 ? (
        <Alert severity="info" sx={{ mb: 2 }}>
          No hay logs para mostrar. Los logs de POST y PATCH se registrarán automáticamente.
        </Alert>
      ) : (
        <TableContainer component={Paper}>
          <Table size="small">
            <TableHead>
              <TableRow sx={{ bgcolor: 'primary.main' }}>
                <TableCell sx={{ color: 'white' }}>Hora</TableCell>
                <TableCell sx={{ color: 'white' }}>Método</TableCell>
                <TableCell sx={{ color: 'white' }}>Endpoint</TableCell>
                <TableCell sx={{ color: 'white' }}>Usuario</TableCell>
                <TableCell sx={{ color: 'white' }} align="center">
                  Estado
                </TableCell>
                <TableCell sx={{ color: 'white' }} align="center">
                  Duración
                </TableCell>
                <TableCell sx={{ color: 'white' }} align="center">
                  Acciones
                </TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {postPatchLogs.map((log) => (
                <TableRow
                  key={log.id}
                  sx={{
                    bgcolor: log.success ? 'success.light' : 'error.light',
                  }}
                >
                  <TableCell>{new Date(log.timestamp).toLocaleTimeString()}</TableCell>
                  <TableCell>
                    <Chip label={log.method} size="small" />
                  </TableCell>
                  <TableCell>{extractEndpoint(log.url)}</TableCell>
                  <TableCell>{log.user.userEmail || 'N/A'}</TableCell>
                  <TableCell align="center">
                    {log.success ? (
                      <CheckCircleIcon color="success" fontSize="small" />
                    ) : (
                      <ErrorIcon color="error" fontSize="small" />
                    )}
                  </TableCell>
                  <TableCell align="center">{log.duration}ms</TableCell>
                  <TableCell align="center">
                    <Button
                      size="small"
                      onClick={() => handleViewDetails(log)}
                    >
                      Ver
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      )}

      {/* Botones de acción */}
      <Box sx={{ mt: 2, display: 'flex', gap: 1 }}>
        <Button
          variant="outlined"
          color="warning"
          onClick={() => clearOldLogs(7)}
          size="small"
        >
          Limpiar logs &gt; 7 días
        </Button>
        <Button
          variant="outlined"
          color="error"
          onClick={handleClearAll}
          startIcon={<DeleteIcon />}
          size="small"
        >
          Eliminar todos
        </Button>
      </Box>

      {/* Dialog de detalles */}
      <Dialog open={detailDialogOpen} onClose={() => setDetailDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>
          Detalles del Log - {selectedLog?.method} {extractEndpoint(selectedLog?.url || '')}
        </DialogTitle>
        <DialogContent sx={{ maxHeight: '70vh', overflow: 'auto' }}>
          {selectedLog && (
            <Box sx={{ mt: 2 }}>
              <Stack spacing={2}>
                {/* Información general */}
                <Paper sx={{ p: 2, bgcolor: 'grey.100' }}>
                  <Typography variant="subtitle2" gutterBottom>
                    Información General
                  </Typography>
                  <Stack direction="row" spacing={2} flexWrap="wrap">
                    <Typography variant="body2">
                      <strong>Hora:</strong> {new Date(selectedLog.timestamp).toLocaleString()}
                    </Typography>
                    <Typography variant="body2">
                      <strong>Usuario:</strong> {selectedLog.user.userEmail}
                    </Typography>
                    <Typography variant="body2">
                      <strong>Duración:</strong> {selectedLog.duration}ms
                    </Typography>
                    <Typography variant="body2">
                      <strong>Estado:</strong>{' '}
                      {selectedLog.success ? (
                        <Chip label="Exitoso" color="success" size="small" />
                      ) : (
                        <Chip label="Fallido" color="error" size="small" />
                      )}
                    </Typography>
                  </Stack>
                </Paper>

                {/* Request */}
                <Accordion>
                  <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                    <Typography variant="subtitle2">Request</Typography>
                  </AccordionSummary>
                  <AccordionDetails>
                    <Paper sx={{ p: 2, bgcolor: 'grey.50', overflow: 'auto', maxHeight: '300px' }}>
                      <pre style={{ margin: 0, fontSize: '0.875rem' }}>
                        {JSON.stringify(selectedLog.request, null, 2)}
                      </pre>
                    </Paper>
                  </AccordionDetails>
                </Accordion>

                {/* Response */}
                {selectedLog.response && (
                  <Accordion>
                    <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                      <Typography variant="subtitle2">Response ({selectedLog.response.status})</Typography>
                    </AccordionSummary>
                    <AccordionDetails>
                      <Paper sx={{ p: 2, bgcolor: 'success.light', overflow: 'auto', maxHeight: '300px' }}>
                        <pre style={{ margin: 0, fontSize: '0.875rem' }}>
                          {JSON.stringify(selectedLog.response, null, 2)}
                        </pre>
                      </Paper>
                    </AccordionDetails>
                  </Accordion>
                )}

                {/* Error */}
                {selectedLog.error && (
                  <Accordion>
                    <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                      <Typography variant="subtitle2" color="error">
                        Error
                      </Typography>
                    </AccordionSummary>
                    <AccordionDetails>
                      <Paper sx={{ p: 2, bgcolor: 'error.light', overflow: 'auto', maxHeight: '300px' }}>
                        <pre style={{ margin: 0, fontSize: '0.875rem' }}>
                          {JSON.stringify(selectedLog.error, null, 2)}
                        </pre>
                      </Paper>
                    </AccordionDetails>
                  </Accordion>
                )}
              </Stack>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button
            startIcon={<ContentCopyIcon />}
            onClick={handleCopyLog}
            variant="outlined"
          >
            {copied ? 'Copiado!' : 'Copiar'}
          </Button>
          <Button onClick={() => setDetailDialogOpen(false)}>Cerrar</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
