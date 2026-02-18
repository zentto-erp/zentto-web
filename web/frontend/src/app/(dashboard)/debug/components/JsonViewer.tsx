'use client';

import React, { useState } from 'react';
import {
  Box,
  Paper,
  IconButton,
  Tooltip,
  Button,
  Typography,
  Stack,
} from '@mui/material';
import {
  ContentCopy as ContentCopyIcon,
  Check as CheckIcon,
  Download as DownloadIcon,
} from '@mui/icons-material';
import { toast } from 'react-hot-toast';

interface JsonViewerProps {
  data: any;
  title?: string;
  showCopyButton?: boolean;
  showDownloadButton?: boolean;
  maxHeight?: number | string;
  bgColor?: string;
  borderColor?: string;
  compact?: boolean;
}

export default function JsonViewer({
  data,
  title,
  showCopyButton = true,
  showDownloadButton = false,
  maxHeight = '500px',
  bgColor,
  borderColor,
  compact = false,
}: JsonViewerProps) {
  const [copied, setCopied] = useState(false);

  const jsonString = JSON.stringify(data, null, 2);

  const handleCopy = () => {
    try {
      navigator.clipboard.writeText(jsonString);
      toast.success('JSON copiado al portapapeles');
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      console.error('Error al copiar:', err);
      toast.error('No se pudo copiar');
    }
  };

  const handleDownload = () => {
    try {
      const blob = new Blob([jsonString], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = title ? `${title.replace(/\s+/g, '_')}.json` : 'data.json';
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      toast.success('JSON descargado');
    } catch (err) {
      console.error('Error al descargar:', err);
      toast.error('No se pudo descargar');
    }
  };

  return (
    <Box sx={{ position: 'relative' }}>
      {title && (
        <Typography variant="subtitle2" gutterBottom>
          {title}
        </Typography>
      )}
      <Paper
        sx={{
          p: compact ? 1 : 2,
          bgcolor: bgColor || 'grey.50',
          border: '1px solid',
          borderColor: borderColor || 'divider',
          maxHeight,
          overflow: 'auto',
          position: 'relative',
          '& pre': {
            margin: 0,
            whiteSpace: 'pre-wrap',
            fontSize: compact ? '0.75rem' : '0.875rem',
            fontFamily: 'monospace',
            lineHeight: 1.5,
            wordBreak: 'break-word',
          },
        }}
      >
        <pre>{jsonString}</pre>
      </Paper>
      
      <Stack 
        direction="row" 
        spacing={1} 
        sx={{
          position: 'absolute',
          top: 8,
          right: 8,
          bgcolor: 'rgba(255, 255, 255, 0.9)',
          borderRadius: '4px',
          p: 0.5,
        }}
      >
        {showCopyButton && (
          <Tooltip title={copied ? 'Copiado!' : 'Copiar JSON'}>
            <IconButton
              onClick={handleCopy}
              size="small"
              sx={{ 
                color: copied ? 'success.main' : 'inherit',
              }}
            >
              {copied ? <CheckIcon fontSize="small" /> : <ContentCopyIcon fontSize="small" />}
            </IconButton>
          </Tooltip>
        )}
        {showDownloadButton && (
          <Tooltip title="Descargar JSON">
            <IconButton
              onClick={handleDownload}
              size="small"
            >
              <DownloadIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        )}
      </Stack>
    </Box>
  );
}
