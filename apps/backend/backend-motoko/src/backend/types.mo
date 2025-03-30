import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Error "mo:base/Error";
import Result "mo:base/Result";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Nat "mo:base/Nat";

module {
    // Tipos de datos
    public type UserId = Principal;
    public type CandidateId = Principal;
    public type DistrictId = Text;
    public type AllianceId = Principal;

    // Tipos de errores
    public type Error = {
        #NotFound;
        #AlreadyExists;
        #NotAuthorized;
        #InvalidInput;
        #DuplicateVote;
        #InvalidDistrict;
        #InvalidAlliance;
    };

    // Tipos de datos principales
    public type User = {
        id: UserId;
        token: Text;  // UUID token for user identification
        role: Text;
        registrationTime: Int;
        districtId: DistrictId;
    };

    public type Candidate = {
        id: CandidateId;
        name: Text;
        alliance: Text;
        districtId: DistrictId;
        registrationTime: Int;
        voteCount: Nat;
    };

    public type Vote = {
        userId: UserId;
        candidateId: CandidateId;
        districtId: DistrictId;
        timestamp: Int;
    };

    // Tipos de estadísticas
    public type VoteStats = {
        totalVotes: Nat;
        districtVotes: [(Text, Nat)];
        candidateVotes: [(Principal, Nat)];
        allianceVotes: [(Principal, Nat)];
    };

    // Tipos de alianzas
    public type Alliance = {
        id: AllianceId;
        name: Text;
        description: Text;
        registrationTime: Int;
        candidateCount: Nat;
        allianceVotes: [(Principal, Nat)];
    };

    // Funciones auxiliares
    public func createError(error: Error) : Result.Result<Any, Error> {
        #err(error)
    };

    public func createSuccess<T>(value: T) : Result.Result<T, Error> {
        #ok(value)
    };

    // Funciones de tiempo
    public func getCurrentTime() : Int {
        Time.now()
    };

    // Funciones de validación
    public func isValidToken(token: Text) : Bool {
        // UUID format validation (8-4-4-4-12 format)
        let parts = Text.split(token, #char '-');
        let partsArray = Iter.toArray(parts);
        if (partsArray.size() != 5) { return false };
        let lengths = [8, 4, 4, 4, 12];
        for (i in Iter.range(0, 4)) {
            if (partsArray[i].size() != lengths[i]) { return false };
        };
        true
    };

    public func isValidDistrict(districtId: Text) : Bool {
        districtId.size() > 0 and districtId.size() <= 50
    };

    public func isValidName(name: Text) : Bool {
        name.size() > 0 and name.size() <= 100
    };
} 