"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import {
  Autocomplete,
  FormControl,
  InputLabel,
  MenuItem,
  Select,
  Stack,
  TextField,
} from "@mui/material";
import { FormDialog, useToast, type CommandSection } from "@zentto/shared-ui";
import {
  useCompaniesList,
  useContactsList,
  useCreateLead,
  usePipelinesList,
  usePipelineStages,
  useUpsertCompany,
  useUpsertContact,
  useUpsertDeal,
  type Company,
  type Contact,
} from "@zentto/module-crm";

export type QuickCreateTarget = "lead" | "contact" | "company" | "deal";

interface QuickCreateContext {
  open: (target: QuickCreateTarget) => void;
  sections: CommandSection[];
}

const Ctx = React.createContext<QuickCreateContext | null>(null);

export function useQuickCreate(): QuickCreateContext {
  const v = React.useContext(Ctx);
  if (!v) throw new Error("useQuickCreate debe usarse dentro de <QuickCreateProvider>");
  return v;
}

const emptyLead = {
  contactName: "",
  companyName: "",
  email: "",
  phone: "",
  priority: "MEDIUM",
};
const emptyContact = { firstName: "", lastName: "", email: "", phone: "" };
const emptyCompany = { name: "", industry: "", email: "", phone: "" };
const emptyDeal = {
  name: "",
  pipelineId: "" as number | "",
  stageId: "" as number | "",
  contactId: "" as number | "",
  crmCompanyId: "" as number | "",
  value: "",
};

/**
 * Provider de QuickCreate. Expone `open('lead' | 'contact' | 'company' | 'deal')`
 * y genera las secciones estáticas del CommandPalette con las acciones rápidas.
 *
 * Los dialogs son mini-forms (campos obligatorios); para detalle completo la UI
 * redirige a la página del registro o deja al usuario editar post-creación.
 */
export default function QuickCreateProvider({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const { showToast } = useToast();

  const [target, setTarget] = React.useState<QuickCreateTarget | null>(null);
  const [leadForm, setLeadForm] = React.useState(emptyLead);
  const [contactForm, setContactForm] = React.useState(emptyContact);
  const [companyForm, setCompanyForm] = React.useState(emptyCompany);
  const [dealForm, setDealForm] = React.useState(emptyDeal);

  const { data: pipelinesData } = usePipelinesList();
  const pipelines =
    (pipelinesData as any)?.data ??
    (pipelinesData as any)?.rows ??
    pipelinesData ??
    [];

  const selectedPipelineId =
    typeof dealForm.pipelineId === "number" ? dealForm.pipelineId : undefined;
  const { data: stagesData } = usePipelineStages(selectedPipelineId);
  const stages =
    (stagesData as any)?.data ?? (stagesData as any)?.rows ?? stagesData ?? [];

  const { data: contactsData } = useContactsList({ active: true, limit: 500 });
  const contacts: Contact[] =
    (contactsData as any)?.data ??
    (contactsData as any)?.rows ??
    contactsData ??
    [];

  const { data: companiesData } = useCompaniesList({ active: true, limit: 500 });
  const companies: Company[] =
    (companiesData as any)?.data ??
    (companiesData as any)?.rows ??
    companiesData ??
    [];

  const createLead = useCreateLead();
  const upsertContact = useUpsertContact();
  const upsertCompany = useUpsertCompany();
  const upsertDeal = useUpsertDeal();

  const open = React.useCallback((t: QuickCreateTarget) => {
    setTarget(t);
    if (t === "lead") setLeadForm(emptyLead);
    else if (t === "contact") setContactForm(emptyContact);
    else if (t === "company") setCompanyForm(emptyCompany);
    else if (t === "deal")
      setDealForm({
        ...emptyDeal,
        pipelineId: (pipelines as any[])[0]?.PipelineId ?? "",
      });
  }, [pipelines]);

  const close = React.useCallback(() => setTarget(null), []);

  /* Handlers */
  const saveLead = () => {
    createLead.mutate(
      {
        contactName: leadForm.contactName.trim(),
        companyName: leadForm.companyName,
        email: leadForm.email,
        phone: leadForm.phone,
        priority: leadForm.priority,
      },
      {
        onSuccess: () => {
          showToast("Lead creado", "success");
          close();
          router.push("/leads");
        },
      },
    );
  };

  const saveContact = () => {
    upsertContact.mutate(
      {
        firstName: contactForm.firstName.trim(),
        lastName: contactForm.lastName || undefined,
        email: contactForm.email || undefined,
        phone: contactForm.phone || undefined,
      },
      {
        onSuccess: (res: any) => {
          showToast("Contacto creado", "success");
          close();
          const id = res?.id ?? res?.ContactId ?? res?.data?.id;
          router.push(id ? `/contactos?contact=${id}` : "/contactos");
        },
      },
    );
  };

  const saveCompany = () => {
    upsertCompany.mutate(
      {
        name: companyForm.name.trim(),
        industry: companyForm.industry || undefined,
        email: companyForm.email || undefined,
        phone: companyForm.phone || undefined,
      },
      {
        onSuccess: (res: any) => {
          showToast("Empresa creada", "success");
          close();
          const id = res?.id ?? res?.CrmCompanyId ?? res?.data?.id;
          router.push(id ? `/empresas?company=${id}` : "/empresas");
        },
      },
    );
  };

  const saveDeal = () => {
    upsertDeal.mutate(
      {
        name: dealForm.name.trim(),
        pipelineId: Number(dealForm.pipelineId),
        stageId: Number(dealForm.stageId),
        contactId: dealForm.contactId ? Number(dealForm.contactId) : undefined,
        crmCompanyId: dealForm.crmCompanyId ? Number(dealForm.crmCompanyId) : undefined,
        value: dealForm.value ? Number(dealForm.value) : undefined,
      } as any,
      {
        onSuccess: (res: any) => {
          showToast("Deal creado", "success");
          close();
          const id = res?.id ?? res?.DealId ?? res?.data?.id;
          router.push(id ? `/deals?deal=${id}` : "/deals");
        },
      },
    );
  };

  /* Palette static sections */
  const sections = React.useMemo<CommandSection[]>(
    () => [
      {
        heading: "Crear",
        items: [
          {
            id: "qc-lead",
            label: "Crear Lead",
            hint: "Nueva oportunidad inicial",
            onSelect: () => open("lead"),
          },
          {
            id: "qc-contact",
            label: "Crear Contacto",
            hint: "Persona individual",
            onSelect: () => open("contact"),
          },
          {
            id: "qc-company",
            label: "Crear Empresa",
            hint: "Organización / cuenta",
            onSelect: () => open("company"),
          },
          {
            id: "qc-deal",
            label: "Crear Deal",
            hint: "Oportunidad con valor",
            onSelect: () => open("deal"),
          },
        ],
      },
      {
        heading: "Navegación",
        items: [
          {
            id: "nav-leads",
            label: "Ir a Leads",
            onSelect: () => router.push("/leads"),
          },
          {
            id: "nav-contactos",
            label: "Ir a Contactos",
            onSelect: () => router.push("/contactos"),
          },
          {
            id: "nav-empresas",
            label: "Ir a Empresas",
            onSelect: () => router.push("/empresas"),
          },
          {
            id: "nav-deals",
            label: "Ir a Deals",
            onSelect: () => router.push("/deals"),
          },
          {
            id: "nav-pipeline",
            label: "Ir a Pipeline",
            onSelect: () => router.push("/pipeline"),
          },
        ],
      },
    ],
    [open, router],
  );

  return (
    <Ctx.Provider value={{ open, sections }}>
      {children}

      <FormDialog
        open={target === "lead"}
        onClose={close}
        title="Nuevo lead rápido"
        onSave={saveLead}
        loading={createLead.isPending}
        disableSave={!leadForm.contactName.trim()}
      >
        <Stack spacing={2} sx={{ mt: 1 }}>
          <TextField
            label="Nombre de contacto"
            fullWidth
            required
            value={leadForm.contactName}
            onChange={(e) => setLeadForm({ ...leadForm, contactName: e.target.value })}
          />
          <TextField
            label="Empresa"
            fullWidth
            value={leadForm.companyName}
            onChange={(e) => setLeadForm({ ...leadForm, companyName: e.target.value })}
          />
          <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
            <TextField
              label="Email"
              fullWidth
              value={leadForm.email}
              onChange={(e) => setLeadForm({ ...leadForm, email: e.target.value })}
            />
            <TextField
              label="Teléfono"
              fullWidth
              value={leadForm.phone}
              onChange={(e) => setLeadForm({ ...leadForm, phone: e.target.value })}
            />
          </Stack>
          <FormControl fullWidth>
            <InputLabel>Prioridad</InputLabel>
            <Select
              value={leadForm.priority}
              label="Prioridad"
              onChange={(e) =>
                setLeadForm({ ...leadForm, priority: String(e.target.value) })
              }
            >
              <MenuItem value="URGENT">Urgente</MenuItem>
              <MenuItem value="HIGH">Alta</MenuItem>
              <MenuItem value="MEDIUM">Media</MenuItem>
              <MenuItem value="LOW">Baja</MenuItem>
            </Select>
          </FormControl>
        </Stack>
      </FormDialog>

      <FormDialog
        open={target === "contact"}
        onClose={close}
        title="Nuevo contacto rápido"
        onSave={saveContact}
        loading={upsertContact.isPending}
        disableSave={!contactForm.firstName.trim()}
      >
        <Stack spacing={2} sx={{ mt: 1 }}>
          <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
            <TextField
              label="Nombre"
              fullWidth
              required
              value={contactForm.firstName}
              onChange={(e) =>
                setContactForm({ ...contactForm, firstName: e.target.value })
              }
            />
            <TextField
              label="Apellido"
              fullWidth
              value={contactForm.lastName}
              onChange={(e) =>
                setContactForm({ ...contactForm, lastName: e.target.value })
              }
            />
          </Stack>
          <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
            <TextField
              label="Email"
              fullWidth
              value={contactForm.email}
              onChange={(e) =>
                setContactForm({ ...contactForm, email: e.target.value })
              }
            />
            <TextField
              label="Teléfono"
              fullWidth
              value={contactForm.phone}
              onChange={(e) =>
                setContactForm({ ...contactForm, phone: e.target.value })
              }
            />
          </Stack>
        </Stack>
      </FormDialog>

      <FormDialog
        open={target === "company"}
        onClose={close}
        title="Nueva empresa rápida"
        onSave={saveCompany}
        loading={upsertCompany.isPending}
        disableSave={!companyForm.name.trim()}
      >
        <Stack spacing={2} sx={{ mt: 1 }}>
          <TextField
            label="Nombre"
            fullWidth
            required
            value={companyForm.name}
            onChange={(e) => setCompanyForm({ ...companyForm, name: e.target.value })}
          />
          <TextField
            label="Industria"
            fullWidth
            value={companyForm.industry}
            onChange={(e) =>
              setCompanyForm({ ...companyForm, industry: e.target.value })
            }
          />
          <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
            <TextField
              label="Email"
              fullWidth
              value={companyForm.email}
              onChange={(e) =>
                setCompanyForm({ ...companyForm, email: e.target.value })
              }
            />
            <TextField
              label="Teléfono"
              fullWidth
              value={companyForm.phone}
              onChange={(e) =>
                setCompanyForm({ ...companyForm, phone: e.target.value })
              }
            />
          </Stack>
        </Stack>
      </FormDialog>

      <FormDialog
        open={target === "deal"}
        onClose={close}
        title="Nuevo deal rápido"
        onSave={saveDeal}
        loading={upsertDeal.isPending}
        disableSave={!dealForm.name.trim() || !dealForm.pipelineId || !dealForm.stageId}
      >
        <Stack spacing={2} sx={{ mt: 1 }}>
          <TextField
            label="Nombre"
            fullWidth
            required
            value={dealForm.name}
            onChange={(e) => setDealForm({ ...dealForm, name: e.target.value })}
          />
          <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
            <FormControl fullWidth required>
              <InputLabel>Pipeline</InputLabel>
              <Select
                value={dealForm.pipelineId}
                label="Pipeline"
                onChange={(e) =>
                  setDealForm({
                    ...dealForm,
                    pipelineId: Number(e.target.value),
                    stageId: "",
                  })
                }
              >
                {(pipelines as any[]).map((p) => (
                  <MenuItem key={p.PipelineId} value={p.PipelineId}>
                    {p.Name}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            <FormControl fullWidth required>
              <InputLabel>Etapa</InputLabel>
              <Select
                value={dealForm.stageId}
                label="Etapa"
                onChange={(e) =>
                  setDealForm({ ...dealForm, stageId: Number(e.target.value) })
                }
              >
                {(stages as any[]).map((s) => (
                  <MenuItem key={s.StageId} value={s.StageId}>
                    {s.Name}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Stack>
          <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
            <Autocomplete
              sx={{ flex: 1 }}
              options={contacts}
              getOptionLabel={(c) =>
                `${c.FirstName ?? ""} ${c.LastName ?? ""}`.trim() || `#${c.ContactId}`
              }
              value={
                contacts.find((c) => c.ContactId === Number(dealForm.contactId)) ?? null
              }
              onChange={(_, v) =>
                setDealForm({ ...dealForm, contactId: v?.ContactId ?? "" })
              }
              renderInput={(params) => <TextField {...params} label="Contacto" />}
            />
            <Autocomplete
              sx={{ flex: 1 }}
              options={companies}
              getOptionLabel={(c) => c.Name ?? `#${c.CrmCompanyId}`}
              value={
                companies.find((c) => c.CrmCompanyId === Number(dealForm.crmCompanyId)) ??
                null
              }
              onChange={(_, v) =>
                setDealForm({ ...dealForm, crmCompanyId: v?.CrmCompanyId ?? "" })
              }
              renderInput={(params) => <TextField {...params} label="Empresa" />}
            />
          </Stack>
          <TextField
            label="Valor"
            type="number"
            fullWidth
            value={dealForm.value}
            onChange={(e) => setDealForm({ ...dealForm, value: e.target.value })}
          />
        </Stack>
      </FormDialog>
    </Ctx.Provider>
  );
}
