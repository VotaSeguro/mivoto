# Sistema de Votación en Internet Computer

Este proyecto implementa un sistema de votación descentralizado en Internet Computer, permitiendo a los usuarios registrar partidos políticos, candidatos y emitir votos de manera segura y transparente.

## Características

- Registro de usuarios con validación de email
- Gestión de partidos políticos
- Registro de candidatos por partido
- Sistema de votación por distrito
- Estadísticas de votación en tiempo real
- Interfaz Candid para interacción con el sistema

## Requisitos

- DFX SDK (versión 0.15.0 o superior)
- Internet Computer CLI (ic)
- Motoko

## Instalación

1. Clonar el repositorio:
```bash
git clone https://github.com/tu-usuario/icp-voting.git
cd icp-voting
```

2. Instalar dependencias:
```bash
dfx start --clean --background
dfx deploy
```

## Uso

### Registro de Usuario
```bash
dfx canister call backend registerUser '("Nombre Usuario", "email@ejemplo.com", "distrito1")'
```

### Registro de Partido
```bash
dfx canister call backend registerParty '("Nombre Partido", "Descripción del partido")'
```

### Registro de Candidato
```bash
dfx canister call backend registerCandidate '({
    name = "Nombre Candidato";
    party = "Nombre Partido";
    districtId = "distrito1";
})'
```

### Emitir Voto
```bash
dfx canister call backend vote '(principal "candidato-id", "distrito1")'
```

### Consultar Estadísticas
```bash
dfx canister call backend getVoteStats
```

## Estructura del Proyecto

```
src/
├── backend/
│   ├── types.mo      # Definiciones de tipos
│   ├── voting.mo     # Lógica principal del sistema de votación
│   └── voting.did    # Interfaz Candid
└── tests/
    └── voting.test.mo # Pruebas del sistema
```

## Pruebas

Para ejecutar las pruebas:
```bash
dfx deploy
dfx canister call test runAllTests
```

## Contribuir

1. Fork el repositorio
2. Crear una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir un Pull Request

## Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## Contacto

Tu Nombre - [@tutwitter](https://twitter.com/tutwitter) - email@ejemplo.com

Link del Proyecto: [https://github.com/tu-usuario/icp-voting](https://github.com/tu-usuario/icp-voting) 