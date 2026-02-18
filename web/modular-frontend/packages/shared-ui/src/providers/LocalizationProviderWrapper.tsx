'use client';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { AdapterDayjs } from '@mui/x-date-pickers/AdapterDayjs';
import 'dayjs/locale/es';

export default function LocalizationProviderWrapper({ children }: { children: React.ReactNode }) {
  return <LocalizationProvider dateAdapter={AdapterDayjs} adapterLocale="es">{children}</LocalizationProvider>;
}
