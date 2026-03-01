'use client';

import Typography from '@mui/material/Typography';
import type { SxProps, Theme } from '@mui/material/styles';

export default function Copyright(props: { sx?: SxProps<Theme> }) {
  return (
    <Typography
      variant="body2"
      align="center"
      {...props}
      sx={[
        { color: 'text.secondary' },
        ...(Array.isArray(props.sx) ? props.sx : [props.sx].filter(Boolean)),
      ]}
    >
      {'© DatqBox '}
      {new Date().getFullYear()}
      {'.'}
    </Typography>
  );
}
