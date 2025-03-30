import Principal "mo:base/Principal";
import Array "mo:base/Array";
import VotingSystem "../backend/voting";

actor class TestVotingSystem() {
    private var testResults : [(Text, Bool)] = [];
    private let testPrincipal = Principal.fromText("bd3sg-teaaa-aaaaa-qaaba-cai");
    private let testUserPrincipal = Principal.fromText("aaaaa-aa");

    // Prueba de registro exitoso de usuario
    public func testRegisterUser() : async () {
        let backend = actor "bkyz2-fmaaa-aaaaa-qaaaq-cai" : VotingSystem.VotingSystem;
        let result = await backend.registerUser("550e8400-e29b-41d4-a716-446655440000", "Zapotlan del Rey", ?testUserPrincipal);

        let success = switch (result) {
            case (#ok(user)) {
                user.token == "550e8400-e29b-41d4-a716-446655440000" and
                user.districtId == "Zapotlan del Rey"
            };
            case (#err(_)) { false };
        };
        recordTestResult("testRegisterUser", success);
    };

    // Prueba de registro duplicado de usuario
    public func testDuplicateUserRegistration() : async () {
        let backend = actor "bkyz2-fmaaa-aaaaa-qaaaq-cai" : VotingSystem.VotingSystem;
        
        // Primero registrar el usuario
        let result1 = await backend.registerUser("550e8400-e29b-41d4-a716-446655440000", "Zapotlan del Rey", ?testUserPrincipal);
        switch (result1) {
            case (#err(_)) {
                recordTestResult("testDuplicateUserRegistration", false);
                return;
            };
            case (#ok(_)) {};
        };

        // Intentar registrar el mismo usuario de nuevo
        let result2 = await backend.registerUser("550e8400-e29b-41d4-a716-446655440000", "San Cristobal", ?testUserPrincipal);
        let success = switch (result2) {
            case (#err(#AlreadyExists)) { true };
            case (_) { false };
        };
        recordTestResult("testDuplicateUserRegistration", success);
    };

    // Prueba de registro exitoso de alianza
    public func testRegisterAlliance() : async () {
        let backend = actor "bkyz2-fmaaa-aaaaa-qaaaq-cai" : VotingSystem.VotingSystem;
        let result = await backend.registerAlliance("Alianza por el Cambio", "Una alianza política por y para la gente", ?testUserPrincipal);
        let success = switch (result) {
            case (#ok(alliance)) {
                alliance.name == "Alianza por el Cambio" and
                alliance.description == "Una alianza política por y para la gente"
            };
            case (#err(_)) { false };
        };
        recordTestResult("testRegisterAlliance", success);
    };

    // Prueba de registro duplicado de alianza
    public func testDuplicateAllianceRegistration() : async () {
        let backend = actor "bkyz2-fmaaa-aaaaa-qaaaq-cai" : VotingSystem.VotingSystem;
        
        // Primero registrar la alianza
        let result1 = await backend.registerAlliance("Alianza por el Cambio", "Una alianza política por y para la gente", ?testUserPrincipal);
        switch (result1) {
            case (#err(_)) {
                recordTestResult("testDuplicateAllianceRegistration", false);
                return;
            };
            case (#ok(_)) {};
        };

        // Intentar registrar la misma alianza de nuevo
        let result2 = await backend.registerAlliance("Alianza por el Cambio", "Una alianza política por y para la gente", ?testUserPrincipal);
        let success = switch (result2) {
            case (#err(#AlreadyExists)) { true };
            case (_) { false };
        };
        recordTestResult("testDuplicateAllianceRegistration", success);
    };

    // Prueba de registro exitoso de candidato
    public func testRegisterCandidate() : async () {
        let backend = actor "bkyz2-fmaaa-aaaaa-qaaaq-cai" : VotingSystem.VotingSystem;
        
        // Primero registrar la alianza
        let allianceResult = await backend.registerAlliance("Alianza por el Cambio", "Una alianza política por y para la gente", ?testUserPrincipal);
        switch (allianceResult) {
            case (#err(_)) {
                recordTestResult("testRegisterCandidate", false);
                return;
            };
            case (#ok(_)) {};
        };

        let candidateData = {
            id = testUserPrincipal;
            name = "Candidato 1";
            alliance = "Alianza por el Cambio";
            districtId = "Zapotlan del Rey";
            registrationTime = 0;
            voteCount = 0;
        };
        let result = await backend.registerCandidate(candidateData.alliance, candidateData.name, candidateData.districtId, ?testUserPrincipal);
        let success = switch (result) {
            case (#ok(candidate)) {
                candidate.name == "Candidato 1" and
                candidate.alliance == "Alianza por el Cambio" and
                candidate.districtId == "Zapotlan del Rey"
            };
            case (#err(_)) { false };
        };
        recordTestResult("testRegisterCandidate", success);
    };

    // Prueba de registro duplicado de candidato
    public func testDuplicateCandidateRegistration() : async () {
        let backend = actor "bkyz2-fmaaa-aaaaa-qaaaq-cai" : VotingSystem.VotingSystem;
        
        // Primero registrar la alianza
        let allianceResult = await backend.registerAlliance("Alianza por el Cambio", "Una alianza política por y para la gente", ?testUserPrincipal);
        switch (allianceResult) {
            case (#err(_)) {
                recordTestResult("testDuplicateCandidateRegistration", false);
                return;
            };
            case (#ok(_)) {};
        };

        // Primero registrar el candidato
        let candidateData = {
            id = testUserPrincipal;
            name = "Candidato 2";
            alliance = "Alianza por el Cambio";
            districtId = "Zapotlan del Rey";
            registrationTime = 0;
            voteCount = 0;
        };
        let result1 = await backend.registerCandidate(candidateData.alliance, candidateData.name, candidateData.districtId, ?testUserPrincipal);
        switch (result1) {
            case (#err(_)) {
                recordTestResult("testDuplicateCandidateRegistration", false);
                return;
            };
            case (#ok(_)) {};
        };

        // Intentar registrar el mismo candidato de nuevo
        let result2 = await backend.registerCandidate(candidateData.alliance, candidateData.name, candidateData.districtId, ?testUserPrincipal);
        let success = switch (result2) {
            case (#err(#AlreadyExists)) { true };
            case (_) { false };
        };
        recordTestResult("testDuplicateCandidateRegistration", success);
    };

    // Prueba de votación
    public func testVote() : async () {
        let backend = actor "bkyz2-fmaaa-aaaaa-qaaaq-cai" : VotingSystem.VotingSystem;
        
        // Primero registrar un usuario de prueba
        let testUserResult = await backend.registerUser("6ba7b810-9dad-11d1-80b4-00c04fd430c8", "Zapotlan del Rey", ?testUserPrincipal);
        switch (testUserResult) {
            case (#err(_)) {
                recordTestResult("testVote", false);
                return;
            };
            case (#ok(_)) {};
        };

        // Registrar la alianza
        let allianceResult = await backend.registerAlliance("Alianza por el Cambio", "Una alianza política por y para la gente", ?testUserPrincipal);
        switch (allianceResult) {
            case (#err(_)) {
                recordTestResult("testVote", false);
                return;
            };
            case (#ok(_)) {};
        };

        // Registrar un candidato
        let candidateData = {
            id = testUserPrincipal;
            name = "Candidato 2";
            alliance = "Alianza por el Cambio";
            districtId = "Zapotlan del Rey";
            registrationTime = 0;
            voteCount = 0;
        };
        let candidateResult = await backend.registerCandidate(candidateData.alliance, candidateData.name, candidateData.districtId, ?testUserPrincipal);
        let candidateId = switch (candidateResult) {
            case (#ok(candidate)) { candidate.id };
            case (#err(_)) { 
                recordTestResult("testVote", false);
                return;
            };
        };

        // Emitir un voto usando el Principal de prueba
        let voteResult = await backend.vote(candidateId, "Zapotlan del Rey", ?testUserPrincipal);
        let success = switch (voteResult) {
            case (#ok(vote)) {
                vote.districtId == "Zapotlan del Rey" and
                vote.candidateId == candidateId
            };
            case (#err(_)) { false };
        };
        recordTestResult("testVote", success);
    };

    // Prueba de estadísticas de votación
    public func testVoteStats() : async () {
        let backend = actor "bkyz2-fmaaa-aaaaa-qaaaq-cai" : VotingSystem.VotingSystem;
        
        // Primero registrar y votar
        await testVote();

        // Obtener estadísticas
        let stats = await backend.getVoteStats();
        let success = stats.totalVotes > 0 and
            stats.districtVotes.size() > 0 and
            stats.candidateVotes.size() > 0;
        recordTestResult("testVoteStats", success);
    };

    // Prueba de consultas por distrito
    public func testDistrictQueries() : async () {
        let backend = actor "bkyz2-fmaaa-aaaaa-qaaaq-cai" : VotingSystem.VotingSystem;
        
        // Primero registrar y votar
        await testVote();

        // Obtener votos por distrito
        let votes = await backend.getVotesByDistrict("Zapotlan del Rey");
        let candidates = await backend.getCandidatesByDistrict("Zapotlan del Rey");

        let success = votes.size() > 0 and candidates.size() > 0;
        recordTestResult("testDistrictQueries", success);
    };

    // Prueba de casos de error
    public func testErrorCases() : async () {
        let backend = actor "bkyz2-fmaaa-aaaaa-qaaaq-cai" : VotingSystem.VotingSystem;
        var success = true;
        
        // Caso 1: Votar sin estar registrado
        let unregisteredVote = await backend.vote(testPrincipal, "Zapotlan del Rey", ?testPrincipal);
        switch (unregisteredVote) {
            case (#err(#NotAuthorized)) { };
            case (_) { success := false };
        };

        // Caso 2: Registrar un usuario y votar por un candidato inexistente
        let userResult = await backend.registerUser("test-token-123", "Zapotlan del Rey", ?testUserPrincipal);
        switch (userResult) {
            case (#err(_)) { success := false };
            case (#ok(_)) {
                let nonExistentVote = await backend.vote(testPrincipal, "Zapotlan del Rey", ?testUserPrincipal);
                switch (nonExistentVote) {
                    case (#err(#NotFound)) { };
                    case (_) { success := false };
                };
            };
        };

        // Caso 3: Votar por un candidato en un distrito diferente al del usuario
        let allianceResult = await backend.registerAlliance("Test Alliance", "Test Description", ?testUserPrincipal);
        switch (allianceResult) {
            case (#err(_)) { success := false };
            case (#ok(_)) {
                let candidateData = {
                    id = testUserPrincipal;
                    name = "Test Candidate";
                    alliance = "Test Alliance";
                    districtId = "Zapopan";  // Distrito diferente al del usuario
                    registrationTime = 0;
                    voteCount = 0;
                };
                let candidateResult = await backend.registerCandidate(candidateData.alliance, candidateData.name, candidateData.districtId, ?testUserPrincipal);
                switch (candidateResult) {
                    case (#ok(candidate)) {
                        // El usuario está registrado en "Zapotlan del Rey" pero intenta votar en "Zapopan"
                        let invalidDistrictVote = await backend.vote(candidate.id, "Zapopan", ?testUserPrincipal);
                        switch (invalidDistrictVote) {
                            case (#err(#InvalidDistrict)) { };
                            case (_) { success := false };
                        };
                    };
                    case (#err(_)) { success := false };
                };
            };
        };

        // Caso 4: Votar por un candidato en el distrito correcto
        let candidateData2 = {
            id = testUserPrincipal;
            name = "Test Candidate 2";
            alliance = "Test Alliance";
            districtId = "Zapotlan del Rey";  // Mismo distrito que el usuario
            registrationTime = 0;
            voteCount = 0;
        };
        let candidateResult2 = await backend.registerCandidate(candidateData2.alliance, candidateData2.name, candidateData2.districtId, ?testUserPrincipal);
        switch (candidateResult2) {
            case (#ok(candidate)) {
                let validVote = await backend.vote(candidate.id, "Zapotlan del Rey", ?testUserPrincipal);
                switch (validVote) {
                    case (#ok(_)) { };
                    case (_) { success := false };
                };
            };
            case (#err(_)) { success := false };
        };

        recordTestResult("testErrorCases", success);
    };

    private func recordTestResult(name : Text, result : Bool) {
        testResults := Array.append(testResults, [(name, result)]);
    };

    // Ejecutar todas las pruebas
    public func runAllTests() : async [(Text, Bool)] {
        let backend = actor "bkyz2-fmaaa-aaaaa-qaaaq-cai" : VotingSystem.VotingSystem;
        await backend.resetState();
        await testRegisterUser();

        await backend.resetState();
        await testDuplicateUserRegistration();

        await backend.resetState();
        await testRegisterAlliance();

        await backend.resetState();
        await testDuplicateAllianceRegistration();

        await backend.resetState();
        await testRegisterCandidate();

        await backend.resetState();
        await testDuplicateCandidateRegistration();

        await backend.resetState();
        await testVote();

        await backend.resetState();
        await testVoteStats();

        await backend.resetState();
        await testDistrictQueries();

        await backend.resetState();
        await testErrorCases();

        testResults
    };
} 