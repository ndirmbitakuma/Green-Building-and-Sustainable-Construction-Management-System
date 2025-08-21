import { describe, it, expect, beforeEach } from "vitest"

describe("Building Registry Contract Tests", () => {
  let contractState = {}
  let nextBuildingId = 1
  let currentBlock = 1000
  
  beforeEach(() => {
    contractState = {
      buildings: new Map(),
      projectPhases: new Map(),
      buildingStakeholders: new Map(),
      buildingMetrics: new Map(),
    }
    nextBuildingId = 1
    currentBlock = 1000
  })
  
  // Mock contract functions for testing
  const mockRegisterBuilding = (name, location, buildingType, totalArea, targetCertification, sustainabilityGoals) => {
    if (!name || name.length === 0) return { error: "ERR-INVALID-INPUT" }
    if (!location || location.length === 0) return { error: "ERR-INVALID-INPUT" }
    if (totalArea <= 0) return { error: "ERR-INVALID-INPUT" }
    
    const buildingId = nextBuildingId++
    
    contractState.buildings.set(buildingId, {
      name,
      owner: "test-principal",
      location,
      buildingType,
      totalArea,
      status: 1, // STATUS-PLANNING
      createdAt: currentBlock,
      updatedAt: currentBlock,
      targetCertification,
      sustainabilityGoals,
    })
    
    contractState.projectPhases.set(`${buildingId}-1`, {
      phaseName: "Planning & Design",
      startDate: currentBlock,
      endDate: null,
      completionPercentage: 0,
      phaseNotes: "Initial project planning phase",
    })
    
    contractState.buildingStakeholders.set(`${buildingId}-test-principal`, {
      role: "Owner",
      permissions: 255,
      addedAt: currentBlock,
    })
    
    return { success: buildingId }
  }
  
  const mockUpdateBuildingStatus = (buildingId, newStatus) => {
    const building = contractState.buildings.get(buildingId)
    if (!building) return { error: "ERR-BUILDING-NOT-FOUND" }
    if (newStatus < 1 || newStatus > 5) return { error: "ERR-INVALID-PHASE" }
    
    building.status = newStatus
    building.updatedAt = currentBlock
    contractState.buildings.set(buildingId, building)
    
    return { success: true }
  }
  
  describe("Building Registration", () => {
    it("should register a new building successfully", () => {
      const result = mockRegisterBuilding(
          "Green Office Complex",
          "123 Sustainable St, Eco City",
          "Commercial",
          50000,
          "LEED Gold",
          "Achieve net-zero energy consumption",
      )
      
      expect(result.success).toBe(1)
      expect(contractState.buildings.has(1)).toBe(true)
      
      const building = contractState.buildings.get(1)
      expect(building.name).toBe("Green Office Complex")
      expect(building.totalArea).toBe(50000)
      expect(building.status).toBe(1)
    })
    
    it("should reject registration with empty name", () => {
      const result = mockRegisterBuilding("", "Location", "Type", 1000, "LEED", "Goals")
      expect(result.error).toBe("ERR-INVALID-INPUT")
    })
    
    it("should reject registration with zero area", () => {
      const result = mockRegisterBuilding("Name", "Location", "Type", 0, "LEED", "Goals")
      expect(result.error).toBe("ERR-INVALID-INPUT")
    })
    
    it("should create initial project phase", () => {
      mockRegisterBuilding("Test Building", "Location", "Type", 1000, "LEED", "Goals")
      expect(contractState.projectPhases.has("1-1")).toBe(true)
      
      const phase = contractState.projectPhases.get("1-1")
      expect(phase.phaseName).toBe("Planning & Design")
      expect(phase.completionPercentage).toBe(0)
    })
    
    it("should add owner as stakeholder", () => {
      mockRegisterBuilding("Test Building", "Location", "Type", 1000, "LEED", "Goals")
      expect(contractState.buildingStakeholders.has("1-test-principal")).toBe(true)
      
      const stakeholder = contractState.buildingStakeholders.get("1-test-principal")
      expect(stakeholder.role).toBe("Owner")
      expect(stakeholder.permissions).toBe(255)
    })
  })
  
  describe("Building Status Updates", () => {
    beforeEach(() => {
      mockRegisterBuilding("Test Building", "Location", "Type", 1000, "LEED", "Goals")
    })
    
    it("should update building status successfully", () => {
      const result = mockUpdateBuildingStatus(1, 2) // STATUS-DESIGN
      expect(result.success).toBe(true)
      
      const building = contractState.buildings.get(1)
      expect(building.status).toBe(2)
    })
    
    it("should reject invalid status values", () => {
      const result = mockUpdateBuildingStatus(1, 6)
      expect(result.error).toBe("ERR-INVALID-PHASE")
    })
    
    it("should reject updates for non-existent buildings", () => {
      const result = mockUpdateBuildingStatus(999, 2)
      expect(result.error).toBe("ERR-BUILDING-NOT-FOUND")
    })
  })
  
  describe("Sustainability Targets", () => {
    it("should validate LEED target points", () => {
      // Mock function for setting sustainability targets
      const mockSetTargets = (buildingId, energyTarget, waterTarget, wasteTarget, carbonTarget, leedPoints) => {
        if (!contractState.buildings.has(buildingId)) return { error: "ERR-BUILDING-NOT-FOUND" }
        if (leedPoints > 110) return { error: "ERR-INVALID-INPUT" }
        
        contractState.buildingMetrics.set(buildingId, {
          energyTarget,
          waterTarget,
          wasteReductionTarget: wasteTarget,
          carbonFootprintTarget: carbonTarget,
          leedTargetPoints: leedPoints,
        })
        return { success: true }
      }
      
      mockRegisterBuilding("Test Building", "Location", "Type", 1000, "LEED", "Goals")
      
      const validResult = mockSetTargets(1, 100, 50, 75, 25, 80)
      expect(validResult.success).toBe(true)
      
      const invalidResult = mockSetTargets(1, 100, 50, 75, 25, 120)
      expect(invalidResult.error).toBe("ERR-INVALID-INPUT")
    })
  })
})
