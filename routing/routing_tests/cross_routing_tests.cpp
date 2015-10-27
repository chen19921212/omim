#include "testing/testing.hpp"

#include "routing/cross_mwm_road_graph.hpp"
#include "routing/cross_mwm_router.hpp"
#include "routing/cross_routing_context.hpp"

#include "coding/reader.hpp"
#include "coding/writer.hpp"

using namespace routing;

namespace
{
// Graph to convertions.
UNIT_TEST(TestCrossRouteConverter)
{
  vector<BorderCross> graphCrosses;
  CrossNode const a(1, "aMap", {0, 0}), b(2, "aMap", {2, 2});
  CrossNode const c(3, "bMap", {3, 3}), d(3, "bMap", {4, 4});
  graphCrosses.emplace_back(a, b);
  graphCrosses.emplace_back(b, c);
  graphCrosses.emplace_back(c, d);
  FeatureGraphNode startGraphNode;
  startGraphNode.node.forward_node_id = 5;
  startGraphNode.mwmName = "aMap";
  FeatureGraphNode finalGraphNode;
  finalGraphNode.node.reverse_node_id = 6;
  finalGraphNode.mwmName = "bMap";
  TCheckedPath route;
  ConvertToSingleRouterTasks(graphCrosses, startGraphNode, finalGraphNode, route);
  TEST_EQUAL(route.size(), 2, ("We have 2 maps aMap and bMap."));
  for (auto const & r : route)
    TEST_EQUAL(r.startNode.mwmName, r.finalNode.mwmName, ());
  TEST_EQUAL(route.front().startNode.node, startGraphNode.node,
             ("Start node must be replaced by origin."));
  TEST_EQUAL(route.back().finalNode.node, finalGraphNode.node,
             ("End node must be replaced by origin."));
}

// Cross routing context tests.
UNIT_TEST(TestContextSerialization)
{
  routing::CrossRoutingContextWriter context;
  routing::CrossRoutingContextReader newContext;

  context.AddIngoingNode(1, ms::LatLon::Zero());
  context.AddIngoingNode(2, ms::LatLon::Zero());
  context.AddOutgoingNode(3, "foo", ms::LatLon::Zero());
  context.AddOutgoingNode(4, "bar", ms::LatLon::Zero());
  context.ReserveAdjacencyMatrix();

  vector<char> buffer;
  MemWriter<vector<char> > writer(buffer);
  context.Save(writer);
  TEST_GREATER(buffer.size(), 5, ("Context serializer make some data"));

  MemReader reader(buffer.data(), buffer.size());
  newContext.Load(reader);
  vector<IngoingCrossNode> ingoingNodes;
  newContext.GetAllIngoingNodes(ingoingNodes);
  TEST_EQUAL(ingoingNodes.size(), 2, ());
  TEST_EQUAL(ingoingNodes[0].m_nodeId, 1, ());
  TEST_EQUAL(ingoingNodes[1].m_nodeId, 2, ());

  vector<OutgoingCrossNode> outgoingNodes;
  newContext.GetAllOutgoingNodes(outgoingNodes);
  TEST_EQUAL(outgoingNodes.size(), 2, ());
  TEST_EQUAL(outgoingNodes[0].m_nodeId, 3, ());
  TEST_EQUAL(newContext.GetOutgoingMwmName(outgoingNodes[0]), string("foo"), ());
  TEST_EQUAL(outgoingNodes[1].m_nodeId, 4, ());
  TEST_EQUAL(newContext.GetOutgoingMwmName(outgoingNodes[1]), string("bar"), ());
}

UNIT_TEST(TestAdjacencyMatrix)
{
  routing::CrossRoutingContextWriter context;
  routing::CrossRoutingContextReader newContext;

  context.AddIngoingNode(1, ms::LatLon::Zero());
  context.AddIngoingNode(2, ms::LatLon::Zero());
  context.AddIngoingNode(3, ms::LatLon::Zero());
  context.AddOutgoingNode(4, "foo", ms::LatLon::Zero());
  context.ReserveAdjacencyMatrix();
  {
    auto ins = context.GetIngoingIterators();
    auto outs = context.GetOutgoingIterators();
    context.SetAdjacencyCost(ins.first, outs.first, 5);
    context.SetAdjacencyCost(ins.first + 1, outs.first, 9);
  }

  vector<char> buffer;
  MemWriter<vector<char> > writer(buffer);
  context.Save(writer);
  TEST_GREATER(buffer.size(), 5, ("Context serializer make some data"));

  MemReader reader(buffer.data(), buffer.size());
  newContext.Load(reader);
  vector<IngoingCrossNode> ingoingNodes;
  newContext.GetAllIngoingNodes(ingoingNodes);
  vector<OutgoingCrossNode> outgoingNodes;
  newContext.GetAllOutgoingNodes(outgoingNodes);
  TEST_EQUAL(newContext.GetAdjacencyCost(ingoingNodes[0], outgoingNodes[0]), 5, ());
  TEST_EQUAL(newContext.GetAdjacencyCost(ingoingNodes[1], outgoingNodes[0]), 9, ());
  TEST_EQUAL(newContext.GetAdjacencyCost(ingoingNodes[2], outgoingNodes[0]),
             routing::INVALID_CONTEXT_EDGE_WEIGHT, ("Default cost"));
}

}
