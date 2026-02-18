'use client';

import { Box, Typography, CircularProgress, Tabs, Tab } from '@mui/material';
import { useState } from 'react';
import RequestLogsViewer from './RequestLogsViewer';
import JsonViewer from './JsonViewer';

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
      id={`debug-tabpanel-${index}`}
      aria-labelledby={`debug-tab-${index}`}
      {...other}
    >
      {value === index && (
        <Box sx={{ p: 2 }}>
          {children}
        </Box>
      )}
    </div>
  );
}

export default function DebugContent() {
  const [activeTab, setActiveTab] = useState(0);

  const handleTabChange = (_: React.SyntheticEvent, newValue: number) => {
    setActiveTab(newValue);
  };

  return (
    <Box>
      <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 2 }}>
        <Tabs
          value={activeTab}
          onChange={handleTabChange}
          aria-label="debug tabs"
        >
          <Tab label="Logs de Requests" id="debug-tab-0" aria-controls="debug-tabpanel-0" />
          <Tab label="Sistema Info" id="debug-tab-1" aria-controls="debug-tabpanel-1" />
        </Tabs>
      </Box>

      <TabPanel value={activeTab} index={0}>
        <RequestLogsViewer />
      </TabPanel>

      <TabPanel value={activeTab} index={1}>
        <Box sx={{ p: 2 }}>
          <Typography variant="h6" gutterBottom>
            Información del Sistema
          </Typography>
          <JsonViewer
            data={{
              timestamp: new Date().toISOString(),
              userAgent: typeof navigator !== 'undefined' ? navigator.userAgent : 'N/A',
              platform: typeof navigator !== 'undefined' ? navigator.platform : 'N/A',
              language: typeof navigator !== 'undefined' ? navigator.language : 'N/A',
              onLine: typeof navigator !== 'undefined' ? navigator.onLine : null,
              environment: process.env.NODE_ENV,
              nextPublicApiBase: process.env.NEXT_PUBLIC_API_BASE,
            }}
            title="Información del Navegador y Entorno"
            showDownloadButton
          />
        </Box>
      </TabPanel>
    </Box>
  );
}
