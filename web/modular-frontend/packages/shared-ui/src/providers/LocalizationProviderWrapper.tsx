'use client';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { AdapterDayjs } from '@mui/x-date-pickers/AdapterDayjs';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import timezone from 'dayjs/plugin/timezone';
import 'dayjs/locale/es';

dayjs.extend(utc);
dayjs.extend(timezone);

export default function LocalizationProviderWrapper({ children }: { children: React.ReactNode }) {
  return <LocalizationProvider dateAdapter={AdapterDayjs} adapterLocale="es">{children}</LocalizationProvider>;
}
