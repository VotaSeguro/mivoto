import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Types "./types";

/// Actor del Sistema de Votación
/// Gestiona el registro de usuarios, candidatos, partidos políticos y la funcionalidad de votación
/// Proporciona estadísticas y consultas para el sistema de votación
actor class VotingSystem() {
    // Alias de tipos para mejor legibilidad del código
    type User = Types.User;
    type Candidate = Types.Candidate;
    type Vote = Types.Vote;
    type Error = Types.Error;
    type VoteStats = Types.VoteStats;
    type Alliance = Types.Alliance;

    /// Variables estables para actualizaciones del sistema
    /// Estos arrays almacenan el estado que necesita ser preservado durante las actualizaciones
    private stable var userEntries : [(Principal, User)] = [];
    private stable var candidateEntries : [(Principal, Candidate)] = [];
    private stable var voteEntries : [(Principal, Vote)] = [];
    private stable var allianceEntries : [(Principal, Alliance)] = [];

    /// Gestión del estado usando HashMaps
    /// Estos HashMaps almacenan el estado actual del sistema
    private var users = HashMap.HashMap<Principal, User>(1, Principal.equal, Principal.hash);
    private var candidates = HashMap.HashMap<Principal, Candidate>(1, Principal.equal, Principal.hash);
    private var votes = HashMap.HashMap<Principal, Vote>(1, Principal.equal, Principal.hash);
    private var alliances = HashMap.HashMap<Principal, Alliance>(1, Principal.equal, Principal.hash);

    /// Hooks de actualización del sistema
    /// preupgrade: Guarda el estado actual en variables estables
    system func preupgrade() {
        userEntries := Iter.toArray(users.entries());
        candidateEntries := Iter.toArray(candidates.entries());
        voteEntries := Iter.toArray(votes.entries());
        allianceEntries := Iter.toArray(alliances.entries());
    };

    /// postupgrade: Restaura el estado desde variables estables
    system func postupgrade() {
        users := HashMap.fromIter<Principal, User>(userEntries.vals(), 1, Principal.equal, Principal.hash);
        candidates := HashMap.fromIter<Principal, Candidate>(candidateEntries.vals(), 1, Principal.equal, Principal.hash);
        votes := HashMap.fromIter<Principal, Vote>(voteEntries.vals(), 1, Principal.equal, Principal.hash);
        alliances := HashMap.fromIter<Principal, Alliance>(allianceEntries.vals(), 1, Principal.equal, Principal.hash);
    };

    /// Función para reiniciar el estado (solo para pruebas)
    public shared(msg) func resetState() : async () {
        users := HashMap.HashMap<Principal, User>(1, Principal.equal, Principal.hash);
        candidates := HashMap.HashMap<Principal, Candidate>(1, Principal.equal, Principal.hash);
        votes := HashMap.HashMap<Principal, Vote>(1, Principal.equal, Principal.hash);
        alliances := HashMap.HashMap<Principal, Alliance>(1, Principal.equal, Principal.hash);
    };

    /// Funciones de Gestión de Alianzas

    /// Registra una nueva alianza política
    /// @param name - Nombre de la alianza
    /// @param description - Descripción de la alianza
    /// @param testPrincipal - Principal ID opcional para pruebas
    /// @return Resultado que contiene la alianza creada o un error
    public shared(msg) func registerAlliance(name: Text, description: Text, testPrincipal: ?Principal) : async Result.Result<Alliance, Error> {
        if (name.size() == 0 or description.size() == 0) {
            return #err(#InvalidInput);
        };

        let userId = switch (testPrincipal) {
            case (?id) { id };
            case null { msg.caller };
        };

        switch (alliances.get(userId)) {
            case (?_) { #err(#AlreadyExists) };
            case null {
                let alliance : Alliance = {
                    id = userId;
                    name = name;
                    description = description;
                    registrationTime = Time.now();
                    candidateCount = 0;
                    allianceVotes = [];
                };
                alliances.put(userId, alliance);
                #ok(alliance)
            };
        }
    };

    /// Obtiene una alianza por su ID
    /// @param allianceId - ID Principal de la alianza
    /// @return Resultado que contiene la alianza o un error si no se encuentra
    public query func getAlliances() : async [Alliance] {
        Iter.toArray(alliances.vals())
    };

    /// Actualiza la información de una alianza existente
    /// @param name - Nuevo nombre para la alianza
    /// @param description - Nueva descripción para la alianza
    /// @return Resultado que contiene la alianza actualizada o un error
    public shared(msg) func updateAlliance(name: Text, description: Text) : async Result.Result<Alliance, Error> {
        if (name.size() == 0 or description.size() == 0) {
            return #err(#InvalidInput);
        };

        let caller = msg.caller;
        switch (alliances.get(caller)) {
            case (?alliance) {
                let updatedAlliance : Alliance = {
                    id = alliance.id;
                    name = name;
                    description = description;
                    registrationTime = alliance.registrationTime;
                    candidateCount = alliance.candidateCount;
                    allianceVotes = alliance.allianceVotes;
                };
                alliances.put(caller, updatedAlliance);
                #ok(updatedAlliance)
            };
            case null { #err(#NotFound) };
        }
    };

    /// Funciones de Gestión de Usuarios

    /// Registra un nuevo usuario en el sistema
    /// @param token - Token del usuario (debe ser válido)
    /// @param districtId - Distrito electoral del usuario
    /// @param testPrincipal - Principal ID opcional para pruebas
    /// @return Resultado que contiene el usuario creado o un error
    public shared(msg) func registerUser(token: Text, districtId: Text, testPrincipal: ?Principal) : async Result.Result<User, Error> {
        if (not Types.isValidToken(token)) {
            return #err(#InvalidInput);
        };

        let userId = switch (testPrincipal) {
            case (?id) { id };
            case null { msg.caller };
        };

        switch (users.get(userId)) {
            case (?_) { #err(#AlreadyExists) };
            case null {
                let user : User = {
                    id = userId;
                    districtId = districtId;
                    registrationTime = Time.now();
                    role = "voter";
                    token = token;
                };
                users.put(userId, user);
                #ok(user)
            };
        }
    };

    /// Obtiene un usuario por su ID
    /// @param userId - ID Principal del usuario
    /// @return Resultado que contiene el usuario o un error si no se encuentra
    public query func getUser(userId : Principal) : async Result.Result<User, Error> {
        switch (users.get(userId)) {
            case (?user) { #ok(user) };
            case null { #err(#NotFound) };
        }
    };

    /// Funciones de Gestión de Candidatos

    /// Registra un nuevo candidato
    /// @param alliance - Nombre de la alianza a la que pertenece el candidato
    /// @param name - Nombre del candidato
    /// @param districtId - Distrito electoral del candidato
    /// @param testPrincipal - Principal ID opcional para pruebas
    /// @return Resultado que contiene el candidato creado o un error
    public shared(msg) func registerCandidate(alliance: Text, name: Text, districtId: Text, testPrincipal: ?Principal) : async Result.Result<Candidate, Error> {
        let userId = switch (testPrincipal) {
            case (?id) { id };
            case null { msg.caller };
        };
        
        // Verificar si la alianza existe
        let allianceEntries = Iter.toArray(alliances.entries());
        let foundAlliance = Array.find<(Principal, Alliance)>(allianceEntries, func((_, a)) : Bool {
            a.name == alliance
        });

        switch (foundAlliance) {
            case null { return #err(#InvalidAlliance) };
            case (?_) {
                switch (candidates.get(userId)) {
                    case (?_) { #err(#AlreadyExists) };
                    case null {
                        let candidate : Candidate = {
                            id = userId;
                            name = name;
                            alliance = alliance;
                            districtId = districtId;
                            voteCount = 0;
                            registrationTime = Time.now();
                        };
                        candidates.put(userId, candidate);

                        // Incrementar el contador de candidatos de la alianza
                        let (allianceId, allianceInfo) = switch (Array.find<(Principal, Alliance)>(allianceEntries, func((_, a)) : Bool {
                            a.name == alliance
                        })) {
                            case (?entry) { entry };
                            case null { return #err(#InvalidAlliance) };
                        };

                        let updatedAlliance : Alliance = {
                            id = allianceInfo.id;
                            name = allianceInfo.name;
                            description = allianceInfo.description;
                            registrationTime = allianceInfo.registrationTime;
                            candidateCount = allianceInfo.candidateCount + 1;
                            allianceVotes = allianceInfo.allianceVotes;
                        };
                        alliances.put(allianceId, updatedAlliance);

                        #ok(candidate)
                    };
                }
            };
        }
    };

    /// Obtiene un candidato por su ID
    /// @param candidateId - ID Principal del candidato
    /// @return Resultado que contiene el candidato o un error si no se encuentra
    public query func getCandidate(candidateId : Principal) : async Result.Result<Candidate, Error> {
        switch (candidates.get(candidateId)) {
            case (?candidate) { #ok(candidate) };
            case null { #err(#NotFound) };
        }
    };

    /// Funciones del Sistema de Votación

    /// Registra un voto para un candidato
    /// @param candidateId - ID del candidato por el que se vota
    /// @param districtId - Distrito donde se emite el voto
    /// @param testPrincipal - Principal ID opcional para pruebas
    /// @return Resultado que contiene el voto registrado o un error
    public shared(msg) func vote(candidateId : Principal, districtId : Text, testPrincipal: ?Principal) : async Result.Result<Vote, Error> {
        let userId = switch (testPrincipal) {
            case (?id) { id };
            case null { msg.caller };
        };
        
        // Verificar si el usuario existe y está en el distrito correcto
        switch (users.get(userId)) {
            case null { return #err(#NotAuthorized) };
            case (?user) {
                if (user.districtId != districtId) {
                    return #err(#InvalidDistrict)
                };
            };
        };

        // Verificar si el candidato existe y está en el distrito correcto
        switch (candidates.get(candidateId)) {
            case null { return #err(#NotFound) };
            case (?candidate) {
                if (candidate.districtId != districtId) {
                    return #err(#InvalidDistrict)
                };
            };
        };

        // Verificar si el usuario ya ha votado
        switch (votes.get(userId)) {
            case (?_) { return #err(#DuplicateVote) };
            case null {
                let vote : Vote = {
                    userId = userId;
                    candidateId = candidateId;
                    districtId = districtId;
                    timestamp = Time.now();
                };
                votes.put(userId, vote);

                // Actualizar el contador de votos del candidato
                switch (candidates.get(candidateId)) {
                    case (?candidate) {
                        let updatedCandidate : Candidate = {
                            id = candidate.id;
                            name = candidate.name;
                            alliance = candidate.alliance;
                            districtId = candidate.districtId;
                            voteCount = candidate.voteCount + 1;
                            registrationTime = candidate.registrationTime;
                        };
                        candidates.put(candidateId, updatedCandidate);

                        // Actualizar votos de la alianza
                        switch (alliances.get(candidate.id)) {
                            case (?alliance) {
                                let updatedAlliance : Alliance = {
                                    id = alliance.id;
                                    name = alliance.name;
                                    description = alliance.description;
                                    registrationTime = alliance.registrationTime;
                                    candidateCount = alliance.candidateCount;
                                    allianceVotes = Array.append(alliance.allianceVotes, [(candidate.id, 1)]);
                                };
                                alliances.put(candidate.id, updatedAlliance);
                            };
                            case null { };
                        };
                    };
                    case null { };
                };

                #ok(vote)
            };
        }
    };

    /// Funciones de Estadísticas y Consultas

    /// Obtiene estadísticas completas de votación
    /// @return Estadísticas de votación que incluyen total de votos, votos por distrito, candidato y partido
    public query func getVoteStats() : async VoteStats {
        var totalVotes = 0;
        let districtVotes = HashMap.HashMap<Text, Nat>(1, Text.equal, Text.hash);
        let candidateVotes = HashMap.HashMap<Principal, Nat>(1, Principal.equal, Principal.hash);
        let allianceVotes = HashMap.HashMap<Principal, Nat>(1, Principal.equal, Principal.hash);

        for ((_, vote) in votes.entries()) {
            totalVotes += 1;
            
            // Actualizar votos por distrito
            let currentDistrictVotes = switch (districtVotes.get(vote.districtId)) {
                case (?count) { count + 1 };
                case null { 1 };
            };
            districtVotes.put(vote.districtId, currentDistrictVotes);

            // Actualizar votos por candidato
            let currentCandidateVotes = switch (candidateVotes.get(vote.candidateId)) {
                case (?count) { count + 1 };
                case null { 1 };
            };
            candidateVotes.put(vote.candidateId, currentCandidateVotes);

            // Actualizar votos por alianza
            switch (candidates.get(vote.candidateId)) {
                case (?candidate) {
                    let currentAllianceVotes = switch (allianceVotes.get(candidate.id)) {
                        case (?count) { count + 1 };
                        case null { 1 };
                    };
                    allianceVotes.put(candidate.id, currentAllianceVotes);
                };
                case null { };
            };
        };

        {
            totalVotes = totalVotes;
            districtVotes = Iter.toArray(districtVotes.entries());
            candidateVotes = Iter.toArray(candidateVotes.entries());
            allianceVotes = Iter.toArray(allianceVotes.entries());
        }
    };

    /// Devuelve todos los votos emitidos en un distrito específico
    /// @param districtId - ID del distrito
    /// @return Array de votos emitidos en el distrito
    public query func getVotesByDistrict(districtId : Text) : async [Vote] {
        Array.filter<Vote>(Iter.toArray(votes.vals()), func(vote : Vote) : Bool {
            vote.districtId == districtId
        })
    };

    /// Devuelve todos los candidatos registrados en un distrito específico
    /// @param districtId - ID del distrito
    /// @return Array de candidatos en el distrito
    public query func getCandidatesByDistrict(districtId : Text) : async [Candidate] {
        Array.filter<Candidate>(Iter.toArray(candidates.vals()), func(candidate : Candidate) : Bool {
            candidate.districtId == districtId
        })
    };
} 