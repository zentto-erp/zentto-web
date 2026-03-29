"use client";

import { useState } from "react";
import { TextField, InputAdornment, IconButton } from "@mui/material";
import SearchIcon from "@mui/icons-material/Search";
import ClearIcon from "@mui/icons-material/Clear";

interface Props {
  value?: string;
  onSearch: (query: string) => void;
  placeholder?: string;
}

export default function SearchBar({ value, onSearch, placeholder = "Buscar productos..." }: Props) {
  const [text, setText] = useState(value ?? "");

  const handleSubmit = (e?: React.FormEvent) => {
    e?.preventDefault();
    onSearch(text.trim());
  };

  const handleClear = () => {
    setText("");
    onSearch("");
  };

  return (
    <form onSubmit={handleSubmit} style={{ width: "100%" }}>
      <TextField
        fullWidth
       
        placeholder={placeholder}
        value={text}
        onChange={(e) => setText(e.target.value)}
        slotProps={{
          input: {
            startAdornment: (
              <InputAdornment position="start">
                <SearchIcon color="action" />
              </InputAdornment>
            ),
            endAdornment: text ? (
              <InputAdornment position="end">
                <IconButton size="small" onClick={handleClear}>
                  <ClearIcon fontSize="small" />
                </IconButton>
              </InputAdornment>
            ) : null,
          },
        }}
      />
    </form>
  );
}
