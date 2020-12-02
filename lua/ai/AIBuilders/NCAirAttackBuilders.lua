--***************************************************************************
--*
--**  File     :  /lua/ai/SorianAirAttackBuilders.lua
--**
--**  Summary  : Default economic builders for skirmish
--**
--**  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local BBTmplFile = '/lua/basetemplates.lua'
local BuildingTmpl = 'BuildingTemplates'
local BaseTmpl = 'BaseTemplates'
local ExBaseTmpl = 'ExpansionBaseTemplates'
local Adj2x2Tmpl = 'Adjacency2x2'
local UCBC = '/lua/editor/UnitCountBuildConditions.lua'
local MIBC = '/lua/editor/MiscBuildConditions.lua'
local MABC = '/lua/editor/MarkerBuildConditions.lua'
local IBC = '/lua/editor/InstantBuildConditions.lua'
local OAUBC = '/lua/editor/OtherArmyUnitCountBuildConditions.lua'
local EBC = '/lua/editor/EconomyBuildConditions.lua'
local TBC = '/lua/editor/ThreatBuildConditions.lua'
local PCBC = '/lua/editor/PlatoonCountBuildConditions.lua'
local SAI = '/lua/ScenarioPlatoonAI.lua'
local PlatoonFile = '/lua/platoon.lua'
local SBC = '/lua/editor/SorianBuildConditions.lua'
local SIBC = '/lua/editor/SorianInstantBuildConditions.lua'

local SUtils = import('/lua/AI/sorianutilities.lua')

function AirAttackCondition(aiBrain, locationType, targetNumber )
	local UC = import('/lua/editor/UnitCountBuildConditions.lua')
    local pool = aiBrain:GetPlatoonUniquelyNamed('ArmyPool')
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
	if not engineerManager then
        return true
    end
	if aiBrain:GetCurrentEnemy() then
		local estartX, estartZ = aiBrain:GetCurrentEnemy():GetArmyStartPos()
		targetNumber = aiBrain:GetThreatAtPosition( {estartX, 0, estartZ}, 1, true, 'AntiAir' )
	end
	
    local position = engineerManager:GetLocationCoords()
    local radius = engineerManager:GetLocationRadius()
    
    --local surfaceThreat = pool:GetPlatoonThreat( 'AntiSurface', categories.MOBILE * categories.AIR - categories.EXPERIMENTAL - categories.SCOUT - categories.INTELLIGENCE, position, radius )
	local surfaceThreat = pool:GetPlatoonThreat( 'AntiSurface', categories.MOBILE * categories.AIR - categories.EXPERIMENTAL - categories.SCOUT - categories.INTELLIGENCE)
    local airThreat = 0 pool:GetPlatoonThreat( 'AntiAir', categories.MOBILE * categories.AIR - categories.EXPERIMENTAL - categories.SCOUT - categories.INTELLIGENCE, position, radius )
    if ( surfaceThreat + airThreat ) >= targetNumber then
        return true
	elseif UC.UnitCapCheckGreater(aiBrain, .95) then
		return true
	elseif SUtils.ThreatBugcheck(aiBrain) then -- added to combat buggy inflated threat
		return true
	elseif UC.PoolGreaterAtLocation(aiBrain, locationType, 0, categories.MOBILE * categories.AIR * categories.TECH3 * (categories.GROUNDATTACK + categories.BOMBER)) and surfaceThreat > 120 then #8 Units x 15
		return true
	elseif UC.PoolGreaterAtLocation(aiBrain, locationType, 0, categories.MOBILE * categories.AIR * categories.TECH2 * (categories.GROUNDATTACK + categories.BOMBER))
	and UC.PoolLessAtLocation(aiBrain, locationType, 1, categories.MOBILE * categories.AIR * categories.TECH3 * (categories.GROUNDATTACK + categories.BOMBER)) and surfaceThreat > 25 then #5 Units x 5
		return true
	elseif UC.PoolLessAtLocation(aiBrain, locationType, 1, categories.MOBILE * categories.AIR * (categories.GROUNDATTACK + categories.BOMBER) - categories.TECH1) and surfaceThreat > 6 then #3 Units x 2
		return true
    end
    return false
end



BuilderGroup {
    BuilderGroupName = 'NCexcessairunitsbehavior',
    BuildersType = 'PlatoonFormBuilder',
      Builder {
        BuilderName = 'NC clenseexcess',
        PlatoonTemplate = 'clenseNC',
		PlatoonAddBehaviors = { 'AirUnitRefitSorian' },
		PlatoonAddPlans = { 'AirIntelToggle' },
        Priority = 10,
        FormRadius = 1000,
        InstanceCount = 20,
        BuilderData = {
            NeverGuardEngineers = true,
        },
        BuilderType = 'Any',
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 6, categories.AIR * categories.MOBILE * categories.ANTIAIR * categories.BOMBER * categories.GROUNDATTACK - categories.TRANSPORTFOCUS - categories.ANTINAVY - categories.SCOUT - categories.EXPERIMENTAL } },
			{ UCBC, 'HaveGreaterThanUnitsInCategoryBeingBuilt', { 0, 'EXPERIMENTAL AIR', 'LocationType', }},
			{ SBC, 'NoRushTimeCheck', { 0 }},
        },
    },
}


BuilderGroup {
    BuilderGroupName = 'NCguardt4airbehavior',
    BuildersType = 'PlatoonFormBuilder',
      Builder {
        BuilderName = 'NC AntiAirT4Guard',
        PlatoonTemplate = 'AntiAirT4GuardNC',
		PlatoonAddBehaviors = { 'AirUnitRefitSorian' },
		PlatoonAddPlans = { 'AirIntelToggle','PlatoonCallForHelpAISorian','DistressResponseAISorian' },
        Priority = 10000,
        FormRadius = 300,
        InstanceCount = 20,
        BuilderData = {
            NeverGuardEngineers = true,
        },
        BuilderType = 'Any',
        BuilderConditions = {
            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, categories.AIR * categories.MOBILE * categories.ANTIAIR - categories.TRANSPORTFOCUS - categories.ANTINAVY - categories.SCOUT } },
			{ UCBC, 'HaveGreaterThanUnitsInCategoryBeingBuilt', { 0, 'EXPERIMENTAL AIR', 'LocationType', }},
			{ SBC, 'NoRushTimeCheck', { 0 }},
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'NCstopfactoryrushwithbombersbehavior',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'NC stop factory rush formbuilder',
        PlatoonTemplate = 'NCfactorystomp',
		PlatoonAddBehaviors = { 'AirUnitRefitSorian' },
		PlatoonAddPlans = { 'AirIntelToggle','DistressResponseAISorian'},
        Priority = 5000,
        InstanceCount = 100,
       
        BuilderType = 'Any',
        BuilderConditions = {
                        
            { MIBC, 'LessThanGameTime', { 840 } },
          { SBC, 'GreaterThanEnemyUnitsAroundBase', { 'LocationType', 5, categories.MOBILE * categories.LAND - categories.SCOUT, 250 } },
                       
                        { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, categories.MOBILE * categories.AIR * categories.BOMBER - categories.EXPERIMENTAL - categories.SCOUT } },
			{ SBC, 'NoRushTimeCheck', { 0 }},
        },
        BuilderData = {
			SearchRadius = 300,
			
            PrioritizedCategories = {    

                              'ENGINEER',
                              'FACTORY LAND',
                              'ALLUNITS',
                                
				
				
            },
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'NCexcessresourcest1bomberbuild',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'NC t1bomber lots of cash',
        PlatoonTemplate = 'T1AirBomber',
        Priority = 500,
        InstanceCount = 30,
        BuilderConditions = {
			
                        { MIBC, 'GreaterThanGameTime', { 1800 } },
			
			
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			
		   { SIBC, 'GreaterThanEconEfficiencyOverTime', { 1.20, 1.20 }},
       
			
        },
        BuilderType = 'Air',
    },
}


BuilderGroup {
    BuilderGroupName = 'NCt3emergencybuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'NC T3AntiAirPlanes - Exp Response build fast',
        PlatoonTemplate = 'T3AirFighter',
        Priority = 850,
        InstanceCount = 100,
        BuilderConditions = {
			{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 0, 'EXPERIMENTAL AIR', 'Enemy'}},
			
			
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			
		
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.80, 1.20 }},
			
        },
        BuilderType = 'Air',
    },
}



BuilderGroup {
    BuilderGroupName = 'NCfindenemyfightersbehavior',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'NC finding enemy fighters',
        PlatoonTemplate = 'NCfighterhunter',
		PlatoonAddBehaviors = { 'AirUnitRefitSorian' },
		PlatoonAddPlans = { 'AirIntelToggle','DistressResponseAISorian'},
        Priority = 100,
        FormRadius = 300,
        InstanceCount = 100,
       
        BuilderType = 'Any',
        BuilderConditions = {
                       
                       
                        { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, categories.MOBILE * categories.AIR * categories.ANTIAIR - categories.BOMBER - categories.GROUNDATTACK - categories.EXPERIMENTAL - categories.TRANSPORTFOCUS - categories.SCOUT } },
			{ SBC, 'NoRushTimeCheck', { 0 }},
        },
        BuilderData = {
			SearchRadius = 6000,
			
            PrioritizedCategories = {    

                                'EXPERIMENTAL AIR',
                                'TRANSPORTFOCUS',
                                'AIR',
                                
				
				
            },
        },
    },
    Builder {
            BuilderName = 'NC finding enemy fighters late',
            PlatoonTemplate = 'NCfighterhunterlate',
            PlatoonAddBehaviors = { 'AirUnitRefitSorian' },
            PlatoonAddPlans = { 'AirIntelToggle','DistressResponseAISorian'},
            Priority = 300,
            FormRadius = 300,
            InstanceCount = 100,
        
            BuilderType = 'Any',
            BuilderConditions = {
                        
                            { MIBC, 'GreaterThanGameTime', { 1320} },
                            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, categories.MOBILE * categories.AIR * categories.ANTIAIR - categories.BOMBER - categories.GROUNDATTACK - categories.EXPERIMENTAL - categories.TRANSPORTFOCUS - categories.SCOUT } },
                { SBC, 'NoRushTimeCheck', { 0 }},
            },
            BuilderData = {
                SearchRadius = 6000,
                
                PrioritizedCategories = {    

                                    'EXPERIMENTAL AIR',
                                    'TRANSPORTFOCUS',
                                    'AIR',
                                    
                    
                    
                },
            },
        },
}

    BuilderGroup {
        BuilderGroupName = 'NCt4airsnipebehavior',
        BuildersType = 'PlatoonFormBuilder',
        Builder {
            BuilderName = 'NC building to kill t4 air',
            PlatoonTemplate = 'NCt4snipe',
            PlatoonAddBehaviors = { 'AirUnitRefitSorian' },
            PlatoonAddPlans = { 'AirIntelToggle','DistressResponseAISorian','PlatoonCallForHelpAISorian'},
            Priority = 5000,
            InstanceCount = 20,
            FormRadius = 500,
            BuilderType = 'Any',
            BuilderConditions = {
                           
                            { UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 0, categories.AIR * categories.EXPERIMENTAL,  'Enemy' }},
                            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, categories.MOBILE * categories.AIR * categories.ANTIAIR - categories.BOMBER - categories.GROUNDATTACK - categories.SCOUT } },
                { SBC, 'NoRushTimeCheck', { 0 }},
            },
            BuilderData = {
                SearchRadius = 5000,
                
                PrioritizedCategories = {    
    
                                    'EXPERIMENTAL AIR',
                                    'MOBILE AIR',
                    
                    
                },
            },
        },
    }


    BuilderGroup {
        BuilderGroupName = 'NCacusnipebehavior',
        BuildersType = 'PlatoonFormBuilder',
        Builder {
            BuilderName = 'NC hunt acu t3bomber',
            PlatoonTemplate = 'NCCommanderSnipe',
            PlatoonAddBehaviors = { 'AirUnitRefitSorian' },
            PlatoonAddPlans = { 'AirIntelToggle','PlatoonCallForHelpAISorian'},
            Priority = 1200,
            InstanceCount = 10,
            BuilderType = 'Any',
            BuilderConditions = {
                            { MIBC, 'GreaterThanGameTime', { 1800 } },
                            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 40, categories.MOBILE * categories.ANTIAIR * categories.TECH3} },
                            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, categories.MOBILE * categories.AIR * ( categories.TECH2 + categories.TECH3) * categories.BOMBER * categories.GROUNDATTACK - categories.ANTINAVY } },
                { SBC, 'NoRushTimeCheck', { 0 }},
            },
            BuilderData = {
                SearchRadius = 100000,
                
                PrioritizedCategories = {    
    
                                    'COMMAND',
                    
                    
                },
            },
        },
    }

    BuilderGroup {
        BuilderGroupName = 'NCacusnipe',
        BuildersType = 'FactoryBuilder',
        Builder {
            BuilderName = 'NC T3 Air Gunship air control',
            PlatoonTemplate = 'T3AirGunship',
            Priority = 750,
            InstanceCount = 2,
            BuilderType = 'Air',
            BuilderConditions = {
                { IBC, 'BrainNotLowPowerMode', {} },
                { SBC, 'NoRushTimeCheck', { 600 }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 40, categories.MOBILE * (categories.TECH2 + categories.TECH3)*categories.ANTIAIR} },
                { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.20 }},
                { MIBC, 'GreaterThanGameTime', { 1800 } },
               
            },
        },
    Builder {
            BuilderName = 'NC T2 Air Gunship air control',
            PlatoonTemplate = 'T2AirGunship',
            Priority = 749,
            InstanceCount = 5,
            BuilderType = 'Air',
            BuilderConditions = {
                { IBC, 'BrainNotLowPowerMode', {} },
                { SBC, 'NoRushTimeCheck', { 600 }},
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 40, categories.MOBILE * (categories.TECH2 + categories.TECH3)*categories.ANTIAIR} },
                { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.20 }},
                { MIBC, 'GreaterThanGameTime', { 1800 } },
                
            },
        },
    
    }


    BuilderGroup {
        BuilderGroupName = 'NCAntiLandQuickBuild',
        BuildersType = 'FactoryBuilder',
        Builder {
            BuilderName = 'NC T3 Air Gunship anti land',
            PlatoonTemplate = 'T3AirGunship',
            Priority = 750,
            BuilderType = 'Air',
            BuilderConditions = {
                { IBC, 'BrainNotLowPowerMode', {} },
                { SBC, 'NoRushTimeCheck', { 600 }},
                { UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 60, categories.LAND * categories.MOBILE - categories.ENGINEER,  'Enemy' }},
                { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.20 }},
                { UCBC, 'HaveLessThanUnitsWithCategory', { 100, categories.AIR * categories.GROUNDATTACK * categories.TECH3 } },
            },
        },
     Builder {
            BuilderName = 'NC T2 Air Gunship anti land',
            PlatoonTemplate = 'T2AirGunship',
            Priority = 759,
            BuilderType = 'Air',
            BuilderConditions = {
                { IBC, 'BrainNotLowPowerMode', {} },
                { SBC, 'NoRushTimeCheck', { 600 }},
                { UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 60, categories.LAND * categories.MOBILE - categories.ENGINEER,  'Enemy' }},
                { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.20 }},
                { UCBC, 'HaveLessThanUnitsWithCategory', { 100, categories.AIR * categories.GROUNDATTACK * categories.TECH3 } },
            },
        },
    Builder {
            BuilderName = 'NC t1bomber anti factory rush',
            PlatoonTemplate = 'T1AirBomber',
            Priority = 1000,
            InstanceCount = 30,
            BuilderType = 'Air',
            BuilderConditions = {
                { IBC, 'BrainNotLowPowerMode', {} },
                { SBC, 'NoRushTimeCheck', { 600 }},
                
                { MIBC, 'LessThanGameTime', { 840 } },
               { SBC, 'GreaterThanEnemyUnitsAroundBase', { 'LocationType', 5, categories.MOBILE * categories.LAND - categories.SCOUT, 250 } },
                { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.01 }},
             
            },
        },      
    }


    BuilderGroup {
        BuilderGroupName = 'NCengihuntairbehavior',
        BuildersType = 'PlatoonFormBuilder',
        Builder {
            BuilderName = 'NC engi hunt bomber',
            PlatoonTemplate = 'ncairengihunt',
            PlatoonAddBehaviors = { 'AirUnitRefitSorian' },
            PlatoonAddPlans = { 'AirIntelToggle','DistressResponseAISorian'   },
            Priority = 1200,
            InstanceCount = 10,
            BuilderType = 'Any',
            BuilderConditions = {
                            { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, categories.AIR * categories.BOMBER * categories.MOBILE * categories.GROUNDATTACK - categories.ANTINAVY - categories.EXPERIMENTAL - categories.ANTIAIR } },
                { SBC, 'NoRushTimeCheck', { 0 }},
            },
            BuilderData = {
                SearchRadius = 10000,
                
                PrioritizedCategories = {    
    'ENGINEER',
                                    'MASSEXTRACTION',
                    
                    
                },
            },
        },
    }

    BuilderGroup {
        BuilderGroupName = 'NCmasshuntairbehavior',
        BuildersType = 'PlatoonFormBuilder',
        Builder {
            BuilderName = 'NC mass hunt bomber',
            PlatoonTemplate = 'ncairengihunt',
            PlatoonAddBehaviors = { 'AirUnitRefitSorian' },
            PlatoonAddPlans = { 'AirIntelToggle', 'DistressResponseAISorian'  },
            Priority = 1200,
            InstanceCount = 10,
            BuilderType = 'Any',
            BuilderConditions = {
                         { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, categories.AIR * categories.BOMBER * categories.MOBILE * categories.GROUNDATTACK - categories.ANTINAVY - categories.EXPERIMENTAL - categories.ANTIAIR } },
                { SBC, 'NoRushTimeCheck', { 0 }},
            },
            BuilderData = {
                SearchRadius = 10000,
                
                PrioritizedCategories = {    
    
                                    'MASSEXTRACTION',
    'ENGINEER',
                    
                    
                },
            },
        },
    }



    BuilderGroup {
        BuilderGroupName = 'NCt1buildonce',
        BuildersType = 'FactoryBuilder',
        Builder {
            BuilderName = 'NC T1 Interceptors build once',
            PlatoonTemplate = 'T1AirFighter',
            Priority = 988,
    InstanceCount = 2,
            BuilderConditions = {
                { UCBC, 'HaveLessThanUnitsWithCategory', { 4, categories.AIR * categories.ANTIAIR * categories.TECH1 } },
        
             
            
                { IBC, 'BrainNotLowPowerMode', {} },
                { SBC, 'NoRushTimeCheck', { 600 }},
                
                { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.55, 1.00 }},
                
                
            },
            BuilderType = 'Air',
            
        },
    }


    BuilderGroup {
        BuilderGroupName = 'NCBaseGuardonebuildbehavior',
        BuildersType = 'PlatoonFormBuilder',
    Builder {
            BuilderName = 'NCbuildoncebaseguard',
            PlatoonTemplate = 'AntiAirBaseGuardNC',
            PlatoonAddBehaviors = { 'AirUnitRefitSorian' },
            PlatoonAddPlans = { 'AirIntelToggle','DistressResponseAISorian'},
            Priority = 5000,
            InstanceCount = 10,
            BuilderType = 'Any',
            BuilderData = {
                LocationType = 'LocationType',
                NeverGuardEngineers = true,
            },
            BuilderConditions = {
                { UCBC, 'PoolGreaterAtLocation', { 'LocationType', 0, categories.AIR * categories.MOBILE * categories.ANTIAIR - categories.EXPERIMENTAL - categories.SCOUT} },
                { SBC, 'NoRushTimeCheck', { 0 }},
            },
        },
    }



BuilderGroup {
    BuilderGroupName = 'NCairstaging',
    BuildersType = 'EngineerBuilder',
Builder {
        BuilderName = 'NC T2 Air Staging Engineer',
        PlatoonTemplate = 'T2EngineerBuilderSorian',
        Priority = 890,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 2, categories.AIRSTAGINGPLATFORM * categories.STRUCTURE}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.6, 1.0 }},
        },
        BuilderType = 'Any',
        BuilderData = {
            NumAssistees = 1,
            Construction = {
                BuildClose = true,
                BuildStructures = {
                    'T2AirStagingPlatform',
                },
                Location = 'LocationType',
            }
        }
    },
}

BuilderGroup {
    BuilderGroupName = 'NCTransportFactoryBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'NC T1 Air Transport',
        PlatoonTemplate = 'T1AirTransport',
        Priority = 658,
        BuilderConditions = {
            { MIBC, 'ArmyNeedsTransports', {} },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, 'TRANSPORTFOCUS' } },
			{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MOBILE * categories.AIR * categories.ANTIAIR } },
			#{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MOBILE * categories.AIR * (categories.BOMBER + categories.GROUNDATTACK)} },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 3, 'TRANSPORTFOCUS' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'TRANSPORTFOCUS' } },
            { IBC, 'BrainNotLowPowerMode', {} },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH1 } },
			#{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.FACTORY * categories.AIR } },
			#{ UCBC, 'HaveLessThanUnitsWithCategory', { 1, 'FACTORY TECH2, FACTORY TECH3' } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.80, 1.20 }},
        },
        BuilderType = 'Air',
    },
      Builder {
        BuilderName = 'NC T1 buildonce',
        PlatoonTemplate = 'T1AirTransport',
        Priority = 750,
       
        BuilderConditions = {
            { MIBC, 'ArmyNeedsTransports', {} },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, 'TRANSPORTFOCUS' } },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 1, 'TRANSPORTFOCUS' } },
		

         
            { IBC, 'BrainNotLowPowerMode', {} },
			
			
           
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'NC T2 Air Transport',
        PlatoonTemplate = 'T2AirTransport',
        Priority = 758,
        BuilderConditions = {
            { MIBC, 'ArmyNeedsTransports', {} },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, 'TRANSPORTFOCUS' } },
			{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MOBILE * categories.AIR * categories.ANTIAIR} },
			#{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MOBILE * categories.AIR * (categories.BOMBER + categories.GROUNDATTACK) - categories.TECH1} },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 12, 'TRANSPORTFOCUS TECH2, TRANSPORTFOCUS TECH3' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'TRANSPORTFOCUS' } },
            { IBC, 'BrainNotLowPowerMode', {} },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH2 } },
			#{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.FACTORY * categories.AIR } },
			#{ UCBC, 'HaveLessThanUnitsWithCategory', { 1, 'FACTORY TECH3' } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.80, 1.20 }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'NC T3 Air Transport',
        PlatoonTemplate = 'T3AirTransport',
        Priority = 758,
        BuilderConditions = {
            { MIBC, 'ArmyNeedsTransports', {} },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, 'TRANSPORTFOCUS' } },
			{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MOBILE * categories.AIR * categories.ANTIAIR * categories.TECH3} },
			#{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MOBILE * categories.AIR * categories.TECH3 * (categories.BOMBER + categories.GROUNDATTACK)} },
            { UCBC, 'HaveLessThanUnitsWithCategory', { 10, 'TRANSPORTFOCUS TECH2, TRANSPORTFOCUS TECH3' } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'TRANSPORTFOCUS' } },
            { IBC, 'BrainNotLowPowerMode', {} },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH3 } },
			#{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 1, categories.FACTORY * categories.AIR } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.80, 1.20 }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'NC T1 Air Transport Default - init',
        PlatoonTemplate = 'T1AirTransport',
        Priority = 701,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, 'TRANSPORTFOCUS' } },
            #{ MIBC, 'ArmyNeedsTransports', {} },
			{ MIBC, 'LessThanGameTime', { 600 } },
			#{ UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.SCOUT}},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, 'TRANSPORTFOCUS' } },
            #{ IBC, 'BrainNotLowPowerMode', {} },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.80, 1.20 }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'NC T1 Air Transport Default',
        PlatoonTemplate = 'T1AirTransport',
        Priority = 600,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, 'TRANSPORTFOCUS' } },
            { MIBC, 'ArmyNeedsTransports', {} },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, 'TRANSPORTFOCUS' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.80, 1.20 }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'NC T2 Air Transport Default',
        PlatoonTemplate = 'T2AirTransport',
        Priority = 700,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, 'TRANSPORTFOCUS TECH2, TRANSPORTFOCUS TECH3' } },
            { MIBC, 'ArmyNeedsTransports', {} },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, 'TRANSPORTFOCUS' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.80, 1.20 }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'NC T3 Air Transport Default',
        PlatoonTemplate = 'T3AirTransport',
        Priority = 700,
        BuilderConditions = {
            { UCBC, 'UnitsLessAtLocation', { 'LocationType', 1, 'TRANSPORTFOCUS TECH2, TRANSPORTFOCUS TECH3' } },
            { MIBC, 'ArmyNeedsTransports', {} },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, 'TRANSPORTFOCUS' } },
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.80, 1.20 }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'NC T1 Air Transport HighNeed',
        PlatoonTemplate = 'T1AirTransport',
        Priority = 750,
        BuilderConditions = {
            { MIBC, 'TransportNeedGreater', { 7 } },
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'TRANSPORTFOCUS' } },
            { IBC, 'BrainNotLowPowerMode', {} },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH1 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.80, 1.20 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'TRANSPORTFOCUS' } },
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 1, 'FACTORY TECH2, FACTORY TECH3' } },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'NC T2 Air Transport HighNeed',
        PlatoonTemplate = 'T2AirTransport',
        Priority = 800,
        BuilderConditions = {
            { MIBC, 'TransportNeedGreater', { 7 } },
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 4, 'TRANSPORTFOCUS' } },
            { IBC, 'BrainNotLowPowerMode', {} },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH2 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.80, 1.20 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 4, categories.FACTORY * categories.AIR } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'TRANSPORTFOCUS' } },
			
        },
        BuilderType = 'Air',
    },
 Builder {
        BuilderName = 'NC T2 Air Transport HighNeed LOTS OF FACTORY',
        PlatoonTemplate = 'T2AirTransport',
        Priority = 800,
        BuilderConditions = {
            { MIBC, 'TransportNeedGreater', { 7 } },
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 4, 'TRANSPORTFOCUS' } },
            { IBC, 'BrainNotLowPowerMode', {} },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH2 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.80, 1.20 }},
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 12, categories.FACTORY * categories.AIR } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, 'TRANSPORTFOCUS' } },
			
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'NC T3 Air Transport HighNeed',
        PlatoonTemplate = 'T3AirTransport',
        Priority = 900,
        BuilderConditions = {
            { MIBC, 'TransportNeedGreater', { 7 } },
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 4, 'TRANSPORTFOCUS' } },
            { IBC, 'BrainNotLowPowerMode', {} },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH3 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.20 }},
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 1, 'TRANSPORTFOCUS' } },
        },
        BuilderType = 'Air',
    },
  Builder {
        BuilderName = 'NC T3 Air Transport HighNeed LOTS OF FACTORY',
        PlatoonTemplate = 'T3AirTransport',
        Priority = 900,
        BuilderConditions = {
            { MIBC, 'TransportNeedGreater', { 7 } },
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 4, 'TRANSPORTFOCUS' } },
            { IBC, 'BrainNotLowPowerMode', {} },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH3 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.20 }},
  { UCBC, 'HaveGreaterThanUnitsWithCategory', { 12, categories.FACTORY * categories.AIR } },
            { UCBC, 'HaveLessThanUnitsInCategoryBeingBuilt', { 3, 'TRANSPORTFOCUS' } },
        },
        BuilderType = 'Air',
    },
    
}

BuilderGroup {
    BuilderGroupName = 'NCAntiNavyQuickBuild',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'NC T3 Air Gunship',
        PlatoonTemplate = 'T3AirGunship',
        Priority = 750,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 1, categories.NAVAL * categories.MOBILE,  'Enemy' }},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.20 }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 100, categories.AIR * categories.GROUNDATTACK * categories.TECH3 } },
        },
    },
     Builder {
        BuilderName = 'NC T3 torp bomber',
        PlatoonTemplate = 'T3TorpedoBomber',
        Priority = 750,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 10, categories.NAVAL * categories.MOBILE,  'Enemy' }},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.20 }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 80, categories.AIR * categories.ANTINAVY * categories.TECH3 } },
        },
    },
    Builder {
        BuilderName = 'NC T2 torp bomber',
        PlatoonTemplate = 'T2AirTorpedoBomber',
        Priority = 749,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 10, categories.NAVAL * categories.MOBILE,  'Enemy' }},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.9, 1.20 }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 40, categories.AIR * categories.ANTINAVY * categories.TECH3 } },
        },
    },
}


BuilderGroup {
    BuilderGroupName = 'NCAntiNavyAirbehavior',
    BuildersType = 'PlatoonFormBuilder',
    Builder {
        BuilderName = 'NC T2 and T3 GunShip Attack Anti Navy',
        PlatoonTemplate = 'navalhunters',
		PlatoonAddBehaviors = { 'AirUnitRefitSorian' },
		PlatoonAddPlans = { 'AirIntelToggle' },
        Priority = 1200,
        FormRadius = 1000,
        InstanceCount = 20,
        BuilderType = 'Any',
        BuilderData = {
			SearchRadius = 6000,
            PrioritizedCategories = {
                                'MOBILE NAVAL',
				'STRUCTURE NAVAL',
                'STRUCTURE DEFENSE ANTINAVY',
                'ALLUNITS',
                                 
				
            },
        },
        BuilderConditions = {
			
			{ UCBC, 'PoolGreaterAtLocation', { 'LocationType', 1, 'AIR MOBILE GROUNDATTACK, AIR MOBILE ANTINAVY' } },
			{ SBC, 'NoRushTimeCheck', { 0 }},
        },
    },

}


BuilderGroup {
    BuilderGroupName = 'NCT1AntiAirBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'NC T1 Interceptors',
        PlatoonTemplate = 'T1AirFighter',
        Priority = 560,
        BuilderConditions = {
        { UCBC, 'HaveLessThanUnitsWithCategory', { 40, categories.AIR * categories.ANTIAIR  - categories.BOMBER - categories.GROUNDATTACK } },
            { UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 0, categories.FACTORY * categories.AIR, 'Enemy'}},
            
			
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.20 }},
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY TECH3' }},
			
        },
        BuilderType = 'Air',
    },
Builder {
        BuilderName = 'NC T1 Interceptors ISLANDMAP',
        PlatoonTemplate = 'T1AirFighter',
        Priority = 760,
        InstanceCount = 30,
        BuilderConditions = {
        { UCBC, 'HaveLessThanUnitsWithCategory', { 50, categories.AIR * categories.ANTIAIR  - categories.BOMBER - categories.GROUNDATTACK } },
            
            { SBC, 'IsIsland', { true } },
			
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.20 }},
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'AIR FACTORY TECH3' }},
			
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'NC T1 Interceptors - Enemy Air',
        PlatoonTemplate = 'T1AirFighter',
        Priority = 730,
        InstanceCount = 10,
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 40, categories.AIR * categories.ANTIAIR  - categories.BOMBER - categories.GROUNDATTACK } },
			{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 5, categories.MOBILE * categories.AIR - categories.SCOUT, 'Enemy'}},
 { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 3, categories.ANTIAIR * categories.AIR - categories.BOMBER } },
            
			
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
		
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.20 }},
			
			
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'NC T1 Interceptors - Enemy Air Extra',
        PlatoonTemplate = 'T1AirFighter',
        Priority = 731,
        InstanceCount = 10,
        BuilderConditions = {
           { UCBC, 'HaveLessThanUnitsWithCategory', { 40, categories.AIR * categories.ANTIAIR  - categories.BOMBER - categories.GROUNDATTACK } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 3, categories.ANTIAIR * categories.AIR - categories.BOMBER - categories.GROUNDATTACK } },
			{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 15, categories.MOBILE * categories.AIR - categories.SCOUT, 'Enemy'}},
           
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.20 }},
			
			
        },
        BuilderType = 'Air',
    },
 
}

BuilderGroup {
    BuilderGroupName = 'NCT3AntiAirBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'NC T3AntiAirPlanes Initial',
        PlatoonTemplate = 'T3AirFighter',
        Priority = 791,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.20 }},
			{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 0, categories.FACTORY * categories.AIR, 'Enemy'}},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.AIR * categories.ANTIAIR * categories.TECH3 - categories.BOMBER - categories.GROUNDATTACK } },
		
	
            
        },
        BuilderType = 'Air',
    },
Builder {
        BuilderName = 'NC T3AntiAirPlanes islandmap',
        PlatoonTemplate = 'T3AirFighter',
        Priority = 791,
InstanceCount = 20,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.20 }},

            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.AIR * categories.ANTIAIR * categories.TECH3 - categories.BOMBER - categories.GROUNDATTACK } },
		{ SBC, 'IsIsland', { true } },
	
            
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'NC T3AntiAirPlanes - Enemy Air',
        PlatoonTemplate = 'T3AirFighter',
        Priority = 792,
        InstanceCount = 10,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 9, categories.MOBILE * categories.AIR - categories.SCOUT, 'Enemy'}},
    
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.20 }},
       { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.AIR * categories.ANTIAIR * categories.TECH3 - categories.BOMBER - categories.GROUNDATTACK } },
			
		
            
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'NC T3AntiAirPlanes - Enemy Air Extra',
        PlatoonTemplate = 'T3AirFighter',
        Priority = 793,
        InstanceCount = 10,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 15, categories.MOBILE * categories.AIR - categories.SCOUT, 'Enemy'}},
    
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.20 }},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 50, categories.AIR * categories.ANTIAIR * categories.TECH3 - categories.BOMBER - categories.GROUNDATTACK } },
			
            
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'NC T3AntiAirPlanes - Enemy Air Extra huge',
        PlatoonTemplate = 'T3AirFighter',
        Priority = 794,
        InstanceCount = 10,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 30, categories.MOBILE * categories.AIR - categories.SCOUT, 'Enemy'}},
     
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.8, 1.20 }},
             { UCBC, 'HaveLessThanUnitsWithCategory', { 60, categories.AIR * categories.ANTIAIR * categories.TECH3 - categories.BOMBER - categories.GROUNDATTACK } },
			
           
        },
        BuilderType = 'Air',
    },
 
}

BuilderGroup {
    BuilderGroupName = 'NCT2AirFactoryBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'NC T2 Air Gunship',
        PlatoonTemplate = 'T2AirGunship',
        Priority = 600,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH2 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 5, 'FACTORY TECH3' }},
        },
    },

   
    Builder {
        BuilderName = 'NC T2FighterBomber',
        PlatoonTemplate = 'T2FighterBomber',
        Priority = 600,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH2 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 5, 'FACTORY TECH3' }},
        },
    },

    Builder {
        BuilderName = 'NC T2 Air Gunship2',
        PlatoonTemplate = 'T2AirGunship',
        Priority = 600,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH2 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 5, 'FACTORY TECH3' }},
        },
    },
    Builder {
        BuilderName = 'NC T2FighterBomber2',
        PlatoonTemplate = 'T2FighterBomber',
        Priority = 600,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH2 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 5, 'FACTORY TECH3' }},
        },
    },
    Builder {
        BuilderName = 'NC T2FighterBomber2 - Exp Response',
        PlatoonTemplate = 'T2FighterBomber',
        Priority = 661,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH2 } },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 50, categories.AIR * categories.BOMBER * categories.TECH2 } },
			{ MIBC, 'FactionIndex', {1, 3, 4}},
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 2, categories.AIR * categories.BOMBER } },
			{ SBC, 'T4ThreatExists', {{'Land', 'Naval', 'Structure'}, (categories.LAND + categories.NAVAL + categories.STRUCTURE + categories.ARTILLERY)}},
			#{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 0, 'EXPERIMENTAL LAND, EXPERIMENTAL NAVAL', 'Enemy'}},
        },
    },
    Builder {
        BuilderName = 'NC T2FighterBomber2 - Exp Response 2',
        PlatoonTemplate = 'T2FighterBomber',
        Priority = 661,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH2 } },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 50, categories.AIR * categories.ANTIAIR * categories.TECH2 } },
			{ MIBC, 'FactionIndex', {2}},
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 2, categories.ANTIAIR * categories.AIR - categories.BOMBER } },
			{ SBC, 'T4ThreatExists', {{'Air'}, categories.AIR}},
			#{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 0, 'EXPERIMENTAL AIR', 'Enemy'}},
        },
    },
   
}


BuilderGroup {
    BuilderGroupName = 'NCT1AirFactoryBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'NC T1 Air Bomber',
        PlatoonTemplate = 'T1AirBomber',
        Priority = 500,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH1 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY TECH3' }},
			{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 2, 'FACTORY TECH2, FACTORY TECH3' }},
        },
    },
    Builder {
        BuilderName = 'NC T1 Air Bomber - Stomp Enemy',
        PlatoonTemplate = 'T1AirBomber',
        Priority = 549,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'LessThanThreatAtEnemyBase', { 'AntiAir', 6 }},
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH1 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY TECH3' }},
			{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 2, 'FACTORY TECH2, FACTORY TECH3' }},
        },
    },
    Builder {
        BuilderName = 'NC T1Gunship',
        PlatoonTemplate = 'T1Gunship',
        Priority = 500,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH1 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY TECH3' }},
			{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 2, 'FACTORY TECH2, FACTORY TECH3' }},
        },
    },
    Builder {
        BuilderName = 'NC T1 Air Fighter',
        PlatoonTemplate = 'T1AirFighter',
        Priority = 0, #500,
        BuilderConditions = {
            #{ UCBC, 'UnitsLessAtLocation', { 'LocationType', 30, categories.AIR * categories.ANTIAIR } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 2, categories.ANTIAIR * categories.AIR - categories.BOMBER } },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH1 } },
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY TECH3' }},
			{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 2, 'FACTORY TECH2, FACTORY TECH3' }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'NC T1 Air Bomber 2',
        PlatoonTemplate = 'T1AirBomber',
        Priority = 500,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH1 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 0, categories.FACTORY * categories.AIR, 'Enemy'}},
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY TECH3' }},
			{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 2, 'FACTORY TECH2, FACTORY TECH3' }},
        },
    },
    Builder {
        BuilderName = 'NC T1Gunship2',
        PlatoonTemplate = 'T1Gunship',
        Priority = 500,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH1 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY TECH3' }},
			{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 2, 'FACTORY TECH2, FACTORY TECH3' }},
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'NCT1AntiAirBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'NC T1 Interceptors',
        PlatoonTemplate = 'T1AirFighter',
        Priority = 555,
        BuilderConditions = {
            #{ UCBC, 'HaveLessThanUnitsWithCategory', { 10, categories.AIR * categories.ANTIAIR * categories.TECH1 } },
			{ SIBC, 'HaveLessThanUnitsForMapSize', { {[256] = 8, [512] = 12, [1024] = 15, [2048] = 20, [4096] = 20}, categories.AIR * categories.ANTIAIR * categories.TECH1}},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.ANTIAIR * categories.AIR - categories.BOMBER } },
			{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 0, categories.FACTORY * categories.AIR, 'Enemy'}},
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH1 } },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY TECH3' }},
			{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 2, 'FACTORY TECH3' }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'NC T1 Interceptors - Enemy Air',
        PlatoonTemplate = 'T1AirFighter',
        Priority = 560,
        BuilderConditions = {
            #{ UCBC, 'HaveLessThanUnitsWithCategory', { 20, categories.AIR * categories.ANTIAIR * categories.TECH1 } },
			#{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 9, categories.MOBILE * categories.AIR - categories.SCOUT, 'Enemy'}},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.ANTIAIR * categories.AIR - categories.BOMBER } },
			{ SBC, 'HaveRatioUnitsWithCategoryAndAlliance', { true, 2, categories.AIR * categories.ANTIAIR * categories.TECH1, categories.MOBILE * categories.AIR - categories.SCOUT, 'Enemy'}},
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH1 } },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY TECH3' }},
			#{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 2, 'FACTORY TECH3' }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'NC T1 Interceptors - Enemy Air Extra',
        PlatoonTemplate = 'T1AirFighter',
        Priority = 0, #560,
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.AIR * categories.ANTIAIR * categories.TECH1 } },
			{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 14, categories.MOBILE * categories.AIR - categories.SCOUT, 'Enemy'}},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 2, categories.ANTIAIR * categories.AIR - categories.BOMBER } },
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH1 } },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY TECH3' }},
			#{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 2, 'FACTORY TECH3' }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'NC T1 Interceptors - Enemy Air Extra 2',
        PlatoonTemplate = 'T1AirFighter',
        Priority = 0, #560,
        BuilderConditions = {
            { UCBC, 'HaveLessThanUnitsWithCategory', { 40, categories.AIR * categories.ANTIAIR * categories.TECH1 } },
			{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 19, categories.MOBILE * categories.AIR - categories.SCOUT, 'Enemy'}},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 3, categories.ANTIAIR * categories.AIR - categories.BOMBER } },
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH1 } },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 2, 'FACTORY TECH3' }},
			#{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 2, 'FACTORY TECH3' }},
			{ UCBC, 'UnitCapCheckLess', { .9 } },
        },
        BuilderType = 'Air',
    },
}

BuilderGroup {
    BuilderGroupName = 'NCT2AirFactoryBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'NC T2 Air Gunship',
        PlatoonTemplate = 'T2AirGunship',
        Priority = 600,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH2 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 5, 'FACTORY TECH3' }},
        },
    },
    Builder {
        BuilderName = 'NC T2 Air Gunship - Anti Navy',
        PlatoonTemplate = 'T2AirGunship',
        Priority = 605,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH2 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 5, 'FACTORY TECH3' }},
			{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 1, categories.STRUCTURE * categories.DEFENSE * categories.ANTINAVY, 'Enemy'}},
        },
    },
    Builder {
        BuilderName = 'NC T2 Air Gunship - Stomp Enemy',
        PlatoonTemplate = 'T2BomberSorian',
        Priority = 649,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'LessThanThreatAtEnemyBase', { 'AntiAir', 18 }},
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH2 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 5, 'FACTORY TECH3' }},
        },
    },
    Builder {
        BuilderName = 'NC T2FighterBomber',
        PlatoonTemplate = 'T2FighterBomber',
        Priority = 600,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH2 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 5, 'FACTORY TECH3' }},
        },
    },
    Builder {
        BuilderName = 'NC T1 Air Fighter - T2',
        PlatoonTemplate = 'T1AirFighter',
        Priority = 0, #600,
        BuilderConditions = {
            #{ UCBC, 'UnitsLessAtLocation', { 'LocationType', 30, categories.AIR * categories.ANTIAIR } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 2, categories.ANTIAIR * categories.AIR - categories.BOMBER } },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH2 } },
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 0, categories.FACTORY * categories.AIR, 'Enemy'}},
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 4, 'FACTORY TECH3' }},
			{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 5, 'FACTORY TECH3' }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'NC T2 Air Gunship2',
        PlatoonTemplate = 'T2AirGunship',
        Priority = 600,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH2 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 5, 'FACTORY TECH3' }},
        },
    },
    Builder {
        BuilderName = 'NC T2FighterBomber2',
        PlatoonTemplate = 'T2FighterBomber',
        Priority = 600,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH2 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 5, 'FACTORY TECH3' }},
        },
    },
    Builder {
        BuilderName = 'NC T2FighterBomber2 - Exp Response',
        PlatoonTemplate = 'T2FighterBomber',
        Priority = 661,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH2 } },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 50, categories.AIR * categories.BOMBER * categories.TECH2 } },
			{ MIBC, 'FactionIndex', {1, 3, 4}},
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 2, categories.AIR * categories.BOMBER } },
			{ SBC, 'T4ThreatExists', {{'Land', 'Naval', 'Structure'}, (categories.LAND + categories.NAVAL + categories.STRUCTURE + categories.ARTILLERY)}},
			#{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 0, 'EXPERIMENTAL LAND, EXPERIMENTAL NAVAL', 'Enemy'}},
        },
    },
    Builder {
        BuilderName = 'NC T2FighterBomber2 - Exp Response 2',
        PlatoonTemplate = 'T2FighterBomber',
        Priority = 661,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH2 } },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 50, categories.AIR * categories.ANTIAIR * categories.TECH2 } },
			{ MIBC, 'FactionIndex', {2}},
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 2, categories.ANTIAIR * categories.AIR - categories.BOMBER } },
			{ SBC, 'T4ThreatExists', {{'Air'}, categories.AIR}},
			#{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 0, 'EXPERIMENTAL AIR', 'Enemy'}},
        },
    },
    Builder {
        BuilderName = 'NC T2 Torpedo Bomber',
        PlatoonTemplate = 'T2AirTorpedoBomber',
        Priority = 649,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 10, categories.AIR * categories.ANTINAVY * categories.TECH2 } },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH2 } },
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 0, 'Naval' } },
			{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 5, 'FACTORY TECH3' }},
        },
    },
}

BuilderGroup {
    BuilderGroupName = 'NCT2AntiAirBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'NC T2AntiAirPlanes Initial Higher Pri',
        PlatoonTemplate = 'T1AirFighter',
        Priority = 655,
        BuilderConditions = {
            #{ UCBC, 'HaveLessThanUnitsWithCategory', { 10, categories.AIR * categories.ANTIAIR * categories.TECH1 } },
			{ SIBC, 'HaveLessThanUnitsForMapSize', { {[256] = 12, [512] = 15, [1024] = 20, [2048] = 30, [4096] = 30}, categories.AIR * categories.ANTIAIR * categories.TECH1}},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.ANTIAIR * categories.AIR - categories.BOMBER } },
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 0, categories.FACTORY * categories.AIR, 'Enemy'}},
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH2 } },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 4, 'FACTORY TECH3' }},
			{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 5, 'FACTORY TECH3' }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'NC T2AntiAirPlanes - Enemy Air',
        PlatoonTemplate = 'T1AirFighter',
        Priority = 660,
        BuilderConditions = {
			#{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 9, categories.MOBILE * categories.AIR - categories.SCOUT, 'Enemy'}},
            #{ UCBC, 'HaveLessThanUnitsWithCategory', { 20, categories.AIR * categories.ANTIAIR * categories.TECH1 } },
			{ SBC, 'HaveRatioUnitsWithCategoryAndAlliance', { true, 2, categories.AIR * categories.ANTIAIR * categories.TECH1, categories.MOBILE * categories.AIR - categories.SCOUT, 'Enemy'}},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 1, categories.ANTIAIR * categories.AIR - categories.BOMBER } },
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH2 } },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 4, 'FACTORY TECH3' }},
			#{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 5, 'FACTORY TECH3' }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'NC T2AntiAirPlanes - Enemy Air Extra',
        PlatoonTemplate = 'T1AirFighter',
        Priority = 0, #660,
        BuilderConditions = {
			{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 14, categories.MOBILE * categories.AIR - categories.SCOUT, 'Enemy'}},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 30, categories.AIR * categories.ANTIAIR * categories.TECH1 } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 2, categories.ANTIAIR * categories.AIR - categories.BOMBER } },
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH2 } },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 4, 'FACTORY TECH3' }},
			#{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 5, 'FACTORY TECH3' }},
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'NC T2AntiAirPlanes - Enemy Air Extra 2',
        PlatoonTemplate = 'T1AirFighter',
        Priority = 0, #660,
        BuilderConditions = {
			{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 19, categories.MOBILE * categories.AIR - categories.SCOUT, 'Enemy'}},
            { UCBC, 'HaveLessThanUnitsWithCategory', { 40, categories.AIR * categories.ANTIAIR * categories.TECH1 } },
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 3, categories.ANTIAIR * categories.AIR - categories.BOMBER } },
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH2 } },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 4, 'FACTORY TECH3' }},
			#{ UCBC, 'FactoryLessAtLocation', { 'LocationType', 5, 'FACTORY TECH3' }},
			{ UCBC, 'UnitCapCheckLess', { .9 } },
        },
        BuilderType = 'Air',
    },
}

BuilderGroup {
    BuilderGroupName = 'NCT3AirFactoryBuilders',
    BuildersType = 'FactoryBuilder',
    Builder {
        BuilderName = 'NC T3 Air Gunship',
        PlatoonTemplate = 'T3AirGunship',
        Priority = 700,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH3 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
        },
    },
    Builder {
        BuilderName = 'NC T3 Air Gunship - Anti Navy',
        PlatoonTemplate = 'T3AirGunship',
        Priority = 705,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH3 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 1, categories.STRUCTURE * categories.DEFENSE * categories.ANTINAVY, 'Enemy'}},
        },
    },
    Builder {
        BuilderName = 'NC T3 Air Bomber',
        PlatoonTemplate = 'T3AirBomber',
        Priority = 700,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH3 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
        },
    },
    Builder {
        BuilderName = 'NC T3 Air Bomber - Exp Response',
        PlatoonTemplate = 'T3AirBomber',
        Priority = 761,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 2, categories.TECH3 * categories.AIR * categories.BOMBER } },
			{ UCBC, 'HaveLessThanUnitsWithCategory', { 50, categories.AIR * categories.BOMBER * categories.TECH3 } },
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH3 } },
            #{ SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
			{ SBC, 'T4ThreatExists', {{'Land', 'Naval', 'Structure'}, (categories.LAND + categories.NAVAL + categories.STRUCTURE + categories.ARTILLERY)}},
			#{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 0, 'EXPERIMENTAL LAND, EXPERIMENTAL NAVAL', 'Enemy'}},
        },
    },
    Builder {
        BuilderName = 'NC T3 Air Bomber - Stomp Enemy',
        PlatoonTemplate = 'T3AirBomber',
        Priority = 754,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { false, 6, categories.MOBILE * categories.AIR - categories.SCOUT, 'Enemy'}},
			{ SBC, 'LessThanThreatAtEnemyBase', { 'AntiAir', 54 }},
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH3 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
        },
    },
    Builder {
        BuilderName = 'NC T3 Air Gunship2',
        PlatoonTemplate = 'T3AirGunship',
        Priority = 700,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH3 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
        },
    },
    Builder {
        BuilderName = 'NC T3 Air Bomber2',
        PlatoonTemplate = 'T3AirBomber',
        Priority = 700,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH3 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
        },
    },
    Builder {
        BuilderName = 'NC T3 Air Fighter',
        PlatoonTemplate = 'T3AirFighter',
        Priority = 0, #700,
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'HaveUnitsWithCategoryAndAlliance', { true, 0, categories.FACTORY * categories.AIR, 'Enemy'}},
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH3 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
            { UCBC, 'LocationFactoriesBuildingLess', { 'LocationType', 2, categories.ANTIAIR * categories.AIR - categories.BOMBER } },
        },
        BuilderType = 'Air',
    },
    Builder {
        BuilderName = 'NC T3 Torpedo Bomber',
        PlatoonTemplate = 'T3TorpedoBomber',
        Priority = 754,
        BuilderType = 'Air',
        BuilderConditions = {
            { IBC, 'BrainNotLowPowerMode', {} },
			{ SBC, 'NoRushTimeCheck', { 600 }},
			{ UCBC, 'FactoryGreaterAtLocation', { 'LocationType', 0, categories.FACTORY * categories.AIR * categories.TECH3 } },
            { SIBC, 'GreaterThanEconEfficiencyOverTime', { 0.85, 1.05 }},
            { TBC, 'EnemyThreatGreaterThanValueAtBase', { 'LocationType', 0, 'Naval' } },
        },
    }
}

