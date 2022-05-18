package game.scenes.virusHunter.shared.data
{
	import game.util.DataUtils;

	public class EnemyWaveParser
	{
		public function EnemyWaveParser()
		{
		}
		
		public function parse(xml:XML):Vector.<EnemyWaveData>
		{
			var waves:Vector.<EnemyWaveData> = new Vector.<EnemyWaveData>();
			var wavesXML:XMLList = xml.children() as XMLList;
			var enemyWaveData:EnemyWaveData;
			var enemyData:WaveEnemyData;
			var enemyGroupData:EnemyGroupData;
			var waveXML:XMLList;
			var groupXML:XMLList;
			var enemyXML:XML;
			
			for (var i:uint = 0; i < wavesXML.length(); i++)
			{	
				waveXML = wavesXML[i].children() as XMLList;
				enemyWaveData = new EnemyWaveData();
				enemyWaveData.groups = new Vector.<EnemyGroupData>();
				
				for (var n:uint = 0; n < waveXML.length(); n++)
				{
					groupXML = waveXML[n].children() as XMLList;
					
					enemyGroupData = new EnemyGroupData();
					enemyGroupData.enemies = new Vector.<WaveEnemyData>();
					enemyGroupData.boss = DataUtils.useBoolean(XML(waveXML[n]).attribute("boss"), false);
					
					for (var m:uint = 0; m < groupXML.length(); m++)
					{
						enemyXML = groupXML[m];
						enemyData = new WaveEnemyData();
						enemyData.level = DataUtils.getNumber(enemyXML.level);
						enemyData.type = DataUtils.getString(enemyXML.type);
						
						enemyGroupData.enemies.push(enemyData);
					}
					
					enemyWaveData.groups.push(enemyGroupData);
				}
				
				waves.push(enemyWaveData);
			}
			
			return(waves);
		}
	}
}