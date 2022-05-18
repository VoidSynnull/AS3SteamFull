package game.scenes.prison.shared
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.hit.Zone;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.entity.character.Score;
	import game.scenes.prison.PrisonEvents;
	import game.scenes.prison.shared.particles.DustFlow;
	import game.scenes.prison.shared.ventPuzzle.VentEnding;
	import game.scenes.prison.shared.ventPuzzle.VentSegment;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.counters.ZeroCounter;
	import org.flintparticles.twoD.zones.Zone2D;
	import org.osflash.signals.Signal;
	
	public class VentPuzzleGroup extends Group
	{
		public static const GROUP_ID:String = "ventPuzzleGroup";
		
		private var _container:DisplayObjectContainer;
		
		public var ventsReady:Signal;
		
		// metal pipes
		private var ventBody:Entity;
		private var ventZone:Entity;
		
		private var userFieldId:String;
		private var ventFieldData:Array;

		private var ventsExposed:Boolean = false;
		
		// directs vents
		private var flaps:Vector.<Entity>;
		private var valves:Vector.<Entity>;
		
		private var startingVentId:String;
		
		// holds event for each vent path terminus
		private var endingVents:Array;
		private var flapLinkMap:Array;
		private var path:Array;
		private var endVent:Entity;

		private var _events:PrisonEvents;
		
		private var dustEmitters:Vector.<Entity>;
		
		private var particleKillZone:Zone2D;
		
		public function VentPuzzleGroup(container:DisplayObjectContainer, flapLinkMap:Array, startingVentId:String, endingVents:Array, userFieldId:String, particleKillZone:Zone2D = null)
		{
			this.flapLinkMap = flapLinkMap;
			this.id = GROUP_ID;
			_container = container;
			this.startingVentId = startingVentId;
			this.endingVents = endingVents;
			this.userFieldId = userFieldId;
			this.particleKillZone = particleKillZone;
			ventsReady = new Signal();
		}
		
		override public function added():void
		{
			shellApi = parent.shellApi;
			
			setupValves();
			
			setupVentBody();
			
			loadUserFieldData();
			
			setupFlowPath();
			
			updateFlowPath();
			
			if(path){
				checkTerminusEvents(path[path.length-1], true, null);
			}
			
			SceneUtil.delay(this,0.1,ventsReady.dispatch);

			super.added();
		}	
		
		private function loadUserFieldData():void
		{
			// get user field for parent scene's pipes and update vent states
			ventFieldData = shellApi.getUserField(userFieldId, shellApi.island);
			if(!ventFieldData){
				// set defaults
				if(userFieldId == _events.VENTS_FIELD_METAL){
					ventFieldData = [90,0,0,0,0,90,0,90,0,0,90,90,90,90,0];
				}
				else if(userFieldId == _events.VENTS_FIELD_MESS){
					ventFieldData = [0,90,0,90,0,90,0,0,90,90,0,90,0,90];
				}
				shellApi.setUserField(userFieldId,ventFieldData,shellApi.island);
			}
		}
		
		private function setupValves():void
		{
			// determine the direction of air flow
			flaps = new Vector.<Entity>();
			var flap:Entity;
			for (var i:int = 0; _container["flap"+i] != null; i++) 
			{
				flap = EntityUtils.createSpatialEntity(this, _container["flap"+i]);
				flap.add(new Id("flap"+i));
				flap.get(Display).visible = false;
				flaps.push(flap);
			}
			
			// click valves to rotate flaps
			valves = new Vector.<Entity>();
			var valve:Entity;
			var inter:Interaction;
			var sceneInter:SceneInteraction;
			for (var j:int = 0; _container["valve"+j] != null; j++) 
			{
				valve = EntityUtils.createSpatialEntity(this, _container["valve"+j],_container);
				valve.add(new Id("valve"+j));
				inter = InteractionCreator.addToEntity(valve,[InteractionCreator.CLICK]);
				//inter.click.add(Command.create(rotateValve, flaps[j]));
				sceneInter = new SceneInteraction();
				sceneInter.minTargetDelta = new Point(50,80);
				sceneInter.reached.add(Command.create(rotateValve, flaps[j]));
				sceneInter.validCharStates = new <String>[CharacterState.STAND];
				valve.add(sceneInter);
				ToolTipCreator.addToEntity(valve);
				Spatial(valve.get(Spatial)).rotation = Spatial(flaps[j].get(Spatial)).rotation;
				valves.push(valve);
			}		
		}
		
		private function rotateValve(pl:Entity, valve:Entity, flap:Entity):void
		{
			CharUtils.setAnim(pl,Score,false,0,0,false,false);
			var rot:Number = valve.get(Spatial).rotation + 90;
			if(rot == 0){
				valve.get(Spatial).rotation = 0;
				flap.get(Spatial).rotation = 0;
				VentSegment(flap.get(VentSegment)).updateRotation(flap.get(Spatial).rotation);
			}
			else if(rot == 90){
				valve.get(Spatial).rotation = 90;
				flap.get(Spatial).rotation = 90;
				VentSegment(flap.get(VentSegment)).updateRotation(flap.get(Spatial).rotation);
			}
			else{
				valve.get(Spatial).rotation = 0;
				flap.get(Spatial).rotation = 0;
			}
			VentSegment(flap.get(VentSegment)).updateRotation(flap.get(Spatial).rotation);
			rotatedFlap(valve,flap);
			// SOUND
		}
		
		private function rotatedFlap(valve:Entity, flap:Entity):void
		{
			var flapId:String = flap.get(Id).id;
			trace("rotated: "+flapId);
			var index:String = flapId.substr(flapId.length-1);
			var spatial:Spatial = flap.get(Spatial);
			ventFieldData[int(index)] = snapRotation(spatial.rotation);
			shellApi.setUserField(userFieldId,ventFieldData,shellApi.island);
			//SOUND
			updateFlowPath();
			if(path){
				SceneUtil.delay(this,0.5,Command.create(showEndVent,path));
				if(path[path.length-2]){
					var prevId:String = path[path.length-2].get(Id).id;
				}
				SceneUtil.delay(this,1.0,Command.create(checkTerminusEvents,path[path.length-1],false,prevId));
			}
		}
		
		private function setupVentBody():void
		{
			//click vent body to show inside tube
			ventBody = EntityUtils.createSpatialEntity(this, _container["vent"]);
			ventBody = TimelineUtils.convertClip(_container["vent"],this,ventBody,null,false);
			ventZone = parent.getEntityById("ventZone");
			var zone:Zone = ventZone.get(Zone);
			zone.entered.add(showVentView);
			zone.exitted.add(hideVentView);
		}
		
		private function hideVentView(...p):void
		{
			ventsExposed = false;
			// hide inside of vents
			Timeline(ventBody.get(Timeline)).gotoAndStop("closed");
			for (var i:int = 0; i < flaps.length; i++) 
			{
				flaps[i].get(Display).visible = false;
			}
			for (var j:int = 0; j < dustEmitters.length; j++) 
			{
				dustEmitters[j].get(Display).visible = false;
			}
		}
		
		private function showVentView(...p):void
		{
			ventsExposed = true;
			// show inside of vents
			Timeline(ventBody.get(Timeline)).gotoAndStop("open");
			for (var i:int = 0; i < flaps.length; i++) 
			{
				flaps[i].get(Display).visible = true;
			}
			for (var j:int = 0; j < dustEmitters.length; j++) 
			{
				dustEmitters[j].get(Display).visible = true;
			}
		}
		
		private function toggleVentView(...p):void
		{
			ventsExposed = !ventsExposed;
			if(ventsExposed){
				// show inside of vents
				Timeline(ventBody.get(Timeline)).gotoAndStop("open");
				for (var i:int = 0; i < flaps.length; i++) 
				{
					flaps[i].get(Display).visible = true;
				}
				for (var j:int = 0; j < dustEmitters.length; j++) 
				{
					dustEmitters[j].get(Display).visible = true;
				}
			}
			else{
				// hide inside of vents
				Timeline(ventBody.get(Timeline)).gotoAndStop("closed");
				for (i = 0; i < flaps.length; i++) 
				{
					flaps[i].get(Display).visible = false;
				}
				for (j = 0; j < dustEmitters.length; j++) 
				{
					dustEmitters[j].get(Display).visible = false;
				}
			}
		}
		
		private function setupFlowPath():void
		{
			// setup componenet's link states, reads big array and sets vent conections
			dustEmitters = new Vector.<Entity>();
			var flap:Entity;
			var spatial:Spatial
			var flow:VentSegment;	
			var links:Array;
			for (var i:int = 0; i < flaps.length; i++) 
			{
				flap = flaps[i];
				spatial = flap.get(Spatial);
				if(ventFieldData[i] != null){
					spatial.rotation = ventFieldData[i];
					if(i<valves.length && valves[i]){
						valves[i].get(Spatial).rotation = spatial.rotation;
					}
				}
				links = flapLinkMap[i];
				flow = new VentSegment(snapRotation(spatial.rotation), links[0], links[1], links[2], links[3], flap.get(Id).id);
				flap.add(flow);
			}
		}
		
		private function snapRotation(rotation:Number):int
		{
			var rot:int = 0;
			if(rotation / 90 > 0){
				rot = 90;	
			}
			else{
				rot = 0;
			}
			return rot;
		}
		
		private function updateFlowPath():void
		{			
			//perform direction checks on all flaps and updates particles and ending location, update particles
			path = new Array();
			var curr:Entity = this.getEntityById(startingVentId);
			var currId:String = startingVentId;
			var vent:VentSegment;
			var next:Entity;
			var nextId:String;
			var prev:Entity;
			var prevId:String = "start";
			for (var i:int = 0; i < flaps.length; i++) 
			{				
				vent = curr.get(VentSegment);
				path.push(curr);
				nextId = vent.getNextVentId(prevId);
				prev = curr;
				prevId = currId;
				next = this.getEntityById(nextId);
				if(!next){
					next = null;
					break;
				}
				else{
					curr = next;
					currId = curr.get(Id).id;
				}
			}
			placeParticles(path);
		}
		
		private function showEndVent(path:Array):void
		{
			// pan to last vent to show new flow path, if path has changed
			if(endVent != path[path.length-1]){
				endVent = path[path.length-1];
				SceneUtil.lockInput(this, true);
				SceneUtil.setCameraTarget(shellApi.sceneManager.currentScene, endVent, false, 0.05);
				SceneUtil.delay(this,1.4,unLock);
			}
		}
		
		private function unLock(...p):void
		{
			SceneUtil.lockInput(this, false);
			SceneUtil.setCameraTarget(shellApi.sceneManager.currentScene, shellApi.player);
		}
		
		private function placeParticles(path:Array):void
		{
			clearParticles();
			
			var vent:VentSegment;
			var emit:DustFlow;
			var comp:Emitter;
			var emitEnt:Entity;
			var curr:Entity
			var next:Entity;
			// align particle
			for (var i:int = 0; i < path.length; i++) 
			{
				curr = path[i];
				vent = curr.get(VentSegment);
				var spatial:Spatial = curr.get(Spatial); 
				next = path[i+1];
				
				emit  = new DustFlow();
				emit.init(0, 100, 8, 1, 0xffffff,particleKillZone);
				emitEnt = EmitterCreator.create(this, Display(flaps[i].get(Display)).container, emit, 0,0, flaps[i],"emit"+i,spatial);
				comp = Emitter(emitEnt.get(Emitter));
				DisplayUtils.moveToBack(emitEnt.get(Display).displayObject);
				dustEmitters.push(emitEnt);
				
				if(next){
					var dir:Number = GeomUtils.degreesBetweenPts(EntityUtils.getPosition(next),EntityUtils.getPosition(curr));
					emit.changeDirection(GeomUtils.degreeToRadian(dir), 100);
				}
			}
			if(vent.down != "end"){
				emit.counter = new ZeroCounter();
			}
			else if(path[path.length-2]){
				var id:String = vent.getNextVentId(path[path.length-2].get(Id).id);
				if(id != "end"){	
					emit.counter = new ZeroCounter();
				}
				else{
					emit.changeDirection(GeomUtils.degreeToRadian(90), 100);
				}
			}
		}
		
		private function clearParticles():void
		{	
			var emit:DustFlow;
			for (var i:int = 0; i < dustEmitters.length; i++) 
			{
				emit = dustEmitters[i].get(Emitter).emitter;
				emit.counter.stop();
				Command.callAfterDelay(killParticle, 1200, dustEmitters[i], i);
			}
			dustEmitters = new Vector.<Entity>();
		}
		
		private function killParticle(ent:Entity, i:int):void
		{
			this.removeEntity(ent);
			ent = null;
		}
		
		private function checkTerminusEvents(terminus:Entity, firstLoad:Boolean = false, inputVentId:String = null):void
		{
			var terminusId:String = terminus.get(Id).id;
			var vent:VentSegment = terminus.get(VentSegment);
			var ventEnding:VentEnding;
			if(inputVentId == null){
				if(path[path.length-2]){
					inputVentId = path[path.length-2].get(Id).id;
				}
			}
			var exitVentId:String = vent.getNextVentId(inputVentId);
			for (var i:int = 0; i < endingVents.length; i++) 
			{
				ventEnding = endingVents[i];
				if(ventEnding.id == terminusId && exitVentId == "end"){
					if(ventEnding.removeEvent){
						shellApi.removeEvent(ventEnding.event);
					}else if(!shellApi.checkEvent(ventEnding.event)){
						if(firstLoad){
							shellApi.completeEvent(ventEnding.event);
						}else{
							shellApi.triggerEvent(ventEnding.event,true);
						}
					}
					return;
				}else{
					// remove all non-matching events
					if(shellApi.checkEvent(ventEnding.event)){
						shellApi.removeEvent(ventEnding.event);
					}
				}
			}
		}
		
		private function endPathConnected(ventEnding:VentEnding):void
		{	
			//complete puzzle, trigger event if ending vent
			if(ventEnding.removeEvent){
				shellApi.removeEvent(ventEnding.event);
			}else if(!shellApi.checkEvent(ventEnding.event)){
				shellApi.triggerEvent(ventEnding.event,true);
			}
		}
		
		
		
		
		
		
		
		
		
		
		
		
		
		
	}
}