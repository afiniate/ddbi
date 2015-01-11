open OUnit2

let invariants _ =
  assert_equal Test_record.name "test_record"

let make _ =
  let back = Test_record_embedded.make ~eb1:"foo" ~eb2:3 () in
  let test_record = Test_record.make ~foo:1 ~foo2:2.0 ~bar:"zoo" ~baz:"zook" ~book_id:"foo"
      ~back () in
  assert_equal 1 @@ Test_record.foo test_record;
  assert_equal 2.0 @@ Test_record.foo2 test_record;
  assert_equal "zoo" @@ Test_record.bar test_record;
  assert_equal "zook" @@ Test_record.baz test_record;
  assert_equal 2 @@ Test_record._vsn test_record;
  assert_equal "foo" @@ Test_record.book_id test_record;
  assert_equal back @@ Test_record.back test_record

  let suite = "Ddbi Tests" >::: ["invariants" >:: invariants;
                                 "basic set/get" >:: make]

let () =
  run_test_tt_main suite
