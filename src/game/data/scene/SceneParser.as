/**
 * Parses XML with scene data.
 */

package game.data.scene
{	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import engine.ShellApi;
	
	import game.util.DataUtils;
	
	public class SceneParser
	{				
		public function parse(xml:XML, shellApi:ShellApi = null):SceneData
		{
			var data:SceneData = new SceneData();
			var layerParser:CameraLayerParser = new CameraLayerParser();
			
			if ( xml.hasOwnProperty("cameraLimits") )
			{
				data.cameraLimits = new Rectangle();
				data.cameraLimits.left 		= DataUtils.getNumber(xml.cameraLimits.left);
				data.cameraLimits.right 	= DataUtils.getNumber(xml.cameraLimits.right);
				data.cameraLimits.top 		= DataUtils.getNumber(xml.cameraLimits.top);
				data.cameraLimits.bottom 	= DataUtils.getNumber(xml.cameraLimits.bottom);
			}
				
			if ( xml.hasOwnProperty("bounds")  )
			{
				data.bounds = new Rectangle();
				data.bounds.left 	= DataUtils.getNumber(xml.bounds.left);
				data.bounds.right 	= DataUtils.getNumber(xml.bounds.right);
				data.bounds.top 	= DataUtils.getNumber(xml.bounds.top);
				data.bounds.bottom 	= DataUtils.getNumber(xml.bounds.bottom);
			}
										
			data.assets = DataUtils.getArray(xml.assets);
			data.data = DataUtils.getArray(xml.data);
			data.absoluteFilePaths = DataUtils.getArray(xml.absoluteFilePaths);
			data.prependTypePath = DataUtils.useBoolean(xml.absoluteFilePaths.attribute("prependTypePath"), true);
			data.saveLocation = DataUtils.useBoolean(xml.saveLocation, true);
			
			if ( xml.hasOwnProperty("layers") )
			{
				data.layers = layerParser.parse(xml.layers, data.assets, data.absoluteFilePaths);
			}
			
			if ( xml.hasOwnProperty("player") )
			{
				data.hasPlayer = true;
				if ( XML(xml.player).hasOwnProperty("defaultPosition") )
				{
					data.startPosition = new Point(DataUtils.getNumber(xml.player.defaultPosition.x), DataUtils.getNumber(xml.player.defaultPosition.y));
				}
				if ( XML(xml.player).hasOwnProperty("defaultDirection") )
				{
					data.startDirection = DataUtils.getString(xml.player.defaultDirection);
				}
				if ( XML(xml.player).hasOwnProperty("scale") )
				{
					data.playerScale = DataUtils.getNumber(xml.player.scale);
				}
			}
			else
			{
				data.hasPlayer = false;
			}
			
			if ( xml.hasOwnProperty("sceneType"))
			{
				data.sceneType = DataUtils.getString(xml.sceneType);
				if (shellApi && shellApi.adManager)
				{
					// pass through ad manager to convert billboard to mainstreet or stay as billboard
					data.sceneType = shellApi.adManager.convertSceneType(data.sceneType);
				}
			}
			
			// flag to force charaters off
			if( xml.hasOwnProperty("noCharacters") )
			{
				data.noCharacters = DataUtils.getBoolean(xml.noCharacters);
			}
			/*
			else
			{
				data.noCharacters = data.data.indexOf("npcs.xml") == -1 && data.hasPlayer == false;
			}
			*/
			if(xml.hasOwnProperty("act"))
			{
				data.actId = "act" + DataUtils.getString(xml.act);
			}

			if(xml.hasOwnProperty("suppressFollower"))
			{
				data.suppressFollower = DataUtils.getBoolean(xml.suppressFollower);
			}
			if(xml.hasOwnProperty("pullFromServer"))
			{
				data.pullFromServer = DataUtils.getBoolean(xml.pullFromServer);
			}
			if(xml.hasOwnProperty("suppressAbility"))
			{
				data.suppressAbility = DataUtils.getBoolean(xml.suppressAbility);
			}

			return(data);
		}
	}
}