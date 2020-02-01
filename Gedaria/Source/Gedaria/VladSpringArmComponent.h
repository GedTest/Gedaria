// Viktor Zwinger ©2020 

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/SpringArmComponent.h"
#include "VladSpringArmComponent.generated.h"

/**
 * 
 */
UCLASS(meta = (BlueprintSpawnableComponent))
class GEDARIA_API UVladSpringArmComponent : public USpringArmComponent
{
	GENERATED_BODY()

public:
	UVladSpringArmComponent();

	//USpringArmComponent* SpringArm = nullptr;
};
