package game.scenes.testIsland.zomCatapult.creators
{
	import ash.core.Entity;
	
	import game.components.entity.Sleep;
	import game.components.entity.character.Character;
	import game.components.entity.character.CharacterMotionControl;
	import game.data.character.LookData;
	import game.scene.template.CharacterGroup;
	import game.scenes.testIsland.zomCatapult.ZomCatapult;
	import game.scenes.testIsland.zomCatapult.components.Zombie;
	import game.util.CharUtils;
	import game.util.SkinUtils;
	
	import nape.phys.Body;
	import nape.phys.BodyType;
	import nape.shape.Polygon;

	public class ZombieCreator
	{
		public function ZombieCreator(scene:ZomCatapult)
		{
			_scene = scene;
		}
		
		
		public function create(number:int = 1):void{
			var charGroup:CharacterGroup = _scene.getGroupById(CharacterGroup.GROUP_ID) as CharacterGroup;
			var lookData:LookData = new LookData();
			
			for(var c:int = 0; c < number; c++){
				_z++;
				charGroup.createNpc("zombie"+_z, lookData, 4000+(Math.random()*300), _scene.sceneData.bounds.height - 100, "left", "", null, npcLoaded);
			}
		}
		
		private function npcLoaded( npc:Entity ):void{
			SkinUtils.setRandomSkin(npc);
			SkinUtils.setSkinPart(npc, SkinUtils.EYES, "zombie");
			SkinUtils.setSkinPart(npc, SkinUtils.SKIN_COLOR, 0x63679F);
			
			// start moving left
			Sleep(npc.get(Sleep)).sleeping = false;
			Sleep(npc.get(Sleep)).ignoreOffscreenSleep = true;
			
			Character(npc.get(Character)).costumizable = false;
			
			npc.add(new CharacterMotionControl());
			npc.add(new Zombie());
			
			CharacterMotionControl(npc.get(CharacterMotionControl)).maxVelocityX = 20+(Math.random()*100);
			
			// add collider
			var npcBody:Body = new Body(BodyType.DYNAMIC);
			npcBody.shapes.add(new Polygon(Polygon.box(40, 80)));
			npcBody.mass = 100;
			npcBody.cbTypes.add(_scene.zombieCollisionType);
			npcBody.userData.entity = npc;
			
			Zombie(npc.get(Zombie)).body = npcBody;
			
			_scene._napeGroup.makeNapeCollider(npc, npcBody);
			
			//var motionTarget:MotionTarget = npc.get(MotionTarget);
			//motionTarget.targetX = 0;
			
			CharUtils.moveToTarget(npc, -100, _scene.sceneData.bounds.height - 100);
		}
		
		private var _scene:ZomCatapult;
		private var _z:int = 0;
	}
}