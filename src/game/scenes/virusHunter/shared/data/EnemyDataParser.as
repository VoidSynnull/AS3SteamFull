package game.scenes.virusHunter.shared.data
{
	import flash.utils.Dictionary;
	
	import game.util.ClassUtils;
	import game.util.DataUtils;

	public class EnemyDataParser
	{
		public function EnemyDataParser()
		{
		}
		
		public function parse(xml:XML):Dictionary
		{
			var allEnemies:Dictionary = new Dictionary();
			var enemiesOfType:Dictionary;
			var allEnemiesXML:XMLList = xml.children() as XMLList;
			var enemiesOfTypeXML:XML;
			var enemyData:EnemyData;
			
			for (var i:uint = 0; i < allEnemiesXML.length(); i++)
			{	
				enemiesOfTypeXML = allEnemiesXML[i];
				
				enemyData = new EnemyData();
				enemyData.type = DataUtils.getString(enemiesOfTypeXML.type);
				enemyData.component = ClassUtils.getClassByName(enemiesOfTypeXML.component);
				enemyData.asset = DataUtils.getString(enemiesOfTypeXML.asset);
				enemyData.segmentAsset = DataUtils.getString(enemiesOfTypeXML.segmentAsset);
				enemyData.tailAsset = DataUtils.getString(enemiesOfTypeXML.tailAsset);
				enemyData.level = DataUtils.getNumber(enemiesOfTypeXML.level);
				enemyData.minVelocity = DataUtils.getNumber(enemiesOfTypeXML.minVelocity);
				enemyData.maxVelocity = DataUtils.getNumber(enemiesOfTypeXML.maxVelocity);
				enemyData.friction = DataUtils.useNumber(enemiesOfTypeXML.friction, 0);
				enemyData.targetOffset = DataUtils.useNumber(enemiesOfTypeXML.targetOffset, 0);
				enemyData.acceleration = DataUtils.getNumber(enemiesOfTypeXML.acceleration);
				enemyData.rotationEasing = DataUtils.getNumber(enemiesOfTypeXML.rotationEasing);
				enemyData.maxDamage = DataUtils.getNumber(enemiesOfTypeXML.maxDamage);
				enemyData.impactDamage = DataUtils.getNumber(enemiesOfTypeXML.impactDamage);
				enemyData.projectileDamage = DataUtils.getNumber(enemiesOfTypeXML.projectileDamage);
				enemyData.followTarget = DataUtils.useBoolean(enemiesOfTypeXML.followTarget, false);
				enemyData.ignoreOffscreenSleep = DataUtils.useBoolean(enemiesOfTypeXML.ignoreOffscreenSleep, true);
				enemyData.faceTarget = DataUtils.useBoolean(enemiesOfTypeXML.faceTarget, false);
				enemyData.value = DataUtils.useNumber(enemiesOfTypeXML.value, 0);
				enemyData.scale = DataUtils.useNumber(enemiesOfTypeXML.scale, 1);
				enemyData.attackDistance = DataUtils.getNumber(enemiesOfTypeXML.attackDistance);
				enemyData.lifetime = DataUtils.useNumber(enemiesOfTypeXML.lifetime, 0);
				enemyData.children = DataUtils.useNumber(enemiesOfTypeXML.children, 0);
				
				if(allEnemies[enemyData.type] == null)
				{
					allEnemies[enemyData.type] = new Dictionary();
				}
				
				allEnemies[enemyData.type][enemyData.level] = enemyData;

			}
			
			return(allEnemies);
		}
	}
}

/*
<type>virus</type>
	<component>game.scenes.virusHunter.shared.components.Virus</component>
	<asset>scenes/virusHunter/shared/virus.swf</asset>
	<level>1</level>
	<maxVelocity>100</maxVelocity>
	<acceleration>20</acceleration>
	<maxDamage>1</maxDamage>
	<impactDamage>.2</impactDamage>
	<projectileDamage>.2</projectileDamage>
*/